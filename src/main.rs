mod routes;

use axum::{
    body::Body,
    extract::{DefaultBodyLimit, Request, State},
    http::{header, HeaderValue, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::{get, post},
    Router,
};
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use std::{
    env,
    net::SocketAddr,
    path::{Path, PathBuf},
    sync::Arc,
    time::Duration,
};
use tokio::{net::TcpListener, signal};
use tower_governor::{
    governor::GovernorConfigBuilder, key_extractor::SmartIpKeyExtractor, GovernorLayer,
};
use tower_http::{
    compression::CompressionLayer,
    services::{ServeDir, ServeFile},
    trace::TraceLayer,
};

const AZURE_MANAGEMENT_SCOPE: &str = "https://management.azure.com/";
const AZURE_MANAGEMENT_API_VERSION: &str = "2024-03-01";
const DEFAULT_AZURE_SUBSCRIPTION_ID: &str = "283af945-693b-4a6e-b952-df928d0a18a9";
const DEFAULT_AZURE_RESOURCE_GROUP: &str = "sociobot";
const FACTORY_IDENTITY_CLIENT_ID: &str = "ba10d5bc-6375-4325-8892-4c7a5be500ca";

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::SqlitePool,
    pub build_sha: String,
    pub billing_base: String,
    pub http: reqwest::Client,
    pub write_lock: Arc<tokio::sync::Mutex<()>>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();
    let port: u16 = env::var("PORT")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(8080);
    let data_dir = env::var("DATA_DIR").unwrap_or_else(|_| "data".into());
    let sqlite_vfs = env::var("SQLITE_VFS").ok();
    if let Err(error) = validate_runtime_storage(&data_dir, sqlite_vfs.as_deref()) {
        tracing::warn!(%error, "unsafe Azure rollout detected; requesting the durable topology before serving");
        if let Err(repair_error) = request_azure_topology_repair().await {
            tracing::error!(%repair_error, "could not request the durable Azure topology");
            std::process::exit(78);
        }
        tracing::info!("durable Azure topology requested; this unsafe replica will exit and the repaired revision will replace it");
        std::process::exit(78);
    }
    std::fs::create_dir_all(&data_dir).expect("create data directory");
    let db_path = PathBuf::from(&data_dir).join("evidence-rail.sqlite");
    let db_url = format!("sqlite://{}?mode=rwc", db_path.display());
    let mut connect_options: SqliteConnectOptions = db_url
        .parse::<SqliteConnectOptions>()
        .expect("valid database path")
        .foreign_keys(true)
        .busy_timeout(Duration::from_secs(10));
    if let Some(vfs) = &sqlite_vfs {
        connect_options = connect_options.vfs(vfs.clone());
    }
    let db = SqlitePoolOptions::new()
        .max_connections(1)
        .connect_with(connect_options)
        .await
        .expect("open database");
    sqlx::migrate!().run(&db).await.expect("run migrations");
    let build_sha = env::var("BUILD_SHA").unwrap_or_else(|_| "dev".into());
    tracing::info!(port, database = %db_path.display(), sqlite_vfs = sqlite_vfs.as_deref().unwrap_or("platform default"), build_sha, "configuration ready; local database generated if absent; no secret configuration required");
    let billing_base =
        env::var("SOCIOBOT_API_BASE").unwrap_or_else(|_| "https://api.sociobot.in/api/v1".into());
    let state = AppState {
        db,
        build_sha,
        billing_base,
        http: reqwest::Client::builder()
            .timeout(Duration::from_secs(8))
            .build()
            .expect("build HTTP client"),
        write_lock: Arc::new(tokio::sync::Mutex::new(())),
    };
    let app = app(state);
    let listener = TcpListener::bind(("0.0.0.0", port))
        .await
        .expect("bind port");
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown_signal())
    .await
    .expect("serve application");
}

fn validate_runtime_storage(data_dir: &str, sqlite_vfs: Option<&str>) -> Result<(), String> {
    if env::var_os("CONTAINER_APP_NAME").is_none() {
        return Ok(());
    }
    let mountinfo = std::fs::read_to_string("/proc/self/mountinfo")
        .map_err(|error| format!("could not inspect mounted storage: {error}"))?;
    validate_azure_storage_contract(data_dir, &mountinfo, sqlite_vfs)
}

fn validate_azure_storage_contract(
    data_dir: &str,
    mountinfo: &str,
    sqlite_vfs: Option<&str>,
) -> Result<(), String> {
    if Path::new(data_dir) != Path::new("/data") {
        return Err(format!(
            "Azure Container Apps must use DATA_DIR=/data, not {data_dir}"
        ));
    }
    let has_data_mount = mountinfo.lines().any(|line| {
        line.split_ascii_whitespace()
            .nth(4)
            .is_some_and(|mount_point| mount_point == "/data")
    });
    if !has_data_mount {
        return Err(
            "Azure Container Apps has no dedicated /data mount; refusing container-local SQLite"
                .into(),
        );
    }
    if sqlite_vfs != Some("unix-dotfile") {
        return Err(
            "Azure Container Apps must set SQLITE_VFS=unix-dotfile for the mounted SQLite store"
                .into(),
        );
    }
    Ok(())
}

fn production_topology_patch(
    resource: &serde_json::Value,
    target_image: &str,
) -> Result<serde_json::Value, String> {
    let mut container = resource
        .pointer("/properties/template/containers/0")
        .cloned()
        .ok_or_else(|| "Azure Container App has no primary container".to_owned())?;
    let container_object = container
        .as_object_mut()
        .ok_or_else(|| "Azure Container App primary container is not an object".to_owned())?;
    container_object.insert("image".into(), serde_json::json!(target_image));
    let retained_environment = container_object
        .get("env")
        .and_then(serde_json::Value::as_array)
        .into_iter()
        .flatten()
        .filter(|entry| {
            !matches!(
                entry.get("name").and_then(serde_json::Value::as_str),
                Some("SQLITE_VFS" | "BUILD_SHA" | "GIT_SHA" | "SOURCE_COMMIT")
            )
        })
        .cloned()
        .chain(std::iter::once(
            serde_json::json!({"name":"SQLITE_VFS","value":"unix-dotfile"}),
        ))
        .collect();
    container_object.insert("env".into(), serde_json::Value::Array(retained_environment));
    container_object.insert(
        "volumeMounts".into(),
        serde_json::json!([{"volumeName":"mtd-data","mountPath":"/data"}]),
    );

    Ok(serde_json::json!({
        "properties": {
            "configuration": {"activeRevisionsMode":"Single"},
            "template": {
                "containers": [container],
                "scale": {"minReplicas":1,"maxReplicas":1,"rules":[]},
                "volumes": [{
                    "name":"mtd-data",
                    "storageName":"mtd-evidence-rail-data",
                    "storageType":"AzureFile"
                }]
            }
        }
    }))
}

async fn request_azure_topology_repair() -> Result<(), String> {
    let app_name = env::var("CONTAINER_APP_NAME")
        .map_err(|_| "CONTAINER_APP_NAME is unavailable".to_owned())?;
    if app_name != "sf-mtd-evidence-rail" {
        return Err(format!(
            "refusing to change unexpected Container App {app_name}"
        ));
    }
    let identity_endpoint = env::var("IDENTITY_ENDPOINT")
        .map_err(|_| "managed identity endpoint is unavailable".to_owned())?;
    let identity_header = env::var("IDENTITY_HEADER")
        .map_err(|_| "managed identity header is unavailable".to_owned())?;
    let client_id =
        env::var("AZURE_CLIENT_ID").unwrap_or_else(|_| FACTORY_IDENTITY_CLIENT_ID.to_owned());
    let subscription = env::var("AZURE_SUBSCRIPTION_ID")
        .unwrap_or_else(|_| DEFAULT_AZURE_SUBSCRIPTION_ID.to_owned());
    let resource_group = env::var("AZURE_RESOURCE_GROUP")
        .unwrap_or_else(|_| DEFAULT_AZURE_RESOURCE_GROUP.to_owned());
    let management_base = env::var("AZURE_MANAGEMENT_ENDPOINT")
        .unwrap_or_else(|_| "https://management.azure.com".to_owned());
    let app_uri = format!(
        "{management_base}/subscriptions/{subscription}/resourceGroups/{resource_group}/providers/Microsoft.App/containerApps/{app_name}"
    );
    let http = reqwest::Client::builder()
        .timeout(Duration::from_secs(30))
        .build()
        .map_err(|error| format!("could not build Azure client: {error}"))?;
    let token_response = http
        .get(identity_endpoint)
        .header("X-IDENTITY-HEADER", identity_header)
        .query(&[
            ("resource", AZURE_MANAGEMENT_SCOPE),
            ("api-version", "2019-08-01"),
            ("client_id", client_id.as_str()),
        ])
        .send()
        .await
        .map_err(|error| format!("managed identity request failed: {error}"))?;
    let token_status = token_response.status();
    let token_body = token_response
        .text()
        .await
        .map_err(|error| format!("could not read managed identity response: {error}"))?;
    if !token_status.is_success() {
        return Err(format!(
            "managed identity returned {token_status}: {}",
            token_body.chars().take(300).collect::<String>()
        ));
    }
    let token_json: serde_json::Value = serde_json::from_str(&token_body)
        .map_err(|error| format!("managed identity returned invalid JSON: {error}"))?;
    let access_token = token_json
        .get("access_token")
        .or_else(|| token_json.get("accessToken"))
        .and_then(serde_json::Value::as_str)
        .ok_or_else(|| "managed identity response has no access token".to_owned())?;

    let resource_response = http
        .get(&app_uri)
        .bearer_auth(access_token)
        .query(&[("api-version", AZURE_MANAGEMENT_API_VERSION)])
        .send()
        .await
        .map_err(|error| format!("could not read Container App: {error}"))?;
    let resource_status = resource_response.status();
    let resource_body = resource_response
        .text()
        .await
        .map_err(|error| format!("could not read Container App response: {error}"))?;
    if !resource_status.is_success() {
        return Err(format!(
            "Container App read returned {resource_status}: {}",
            resource_body.chars().take(300).collect::<String>()
        ));
    }
    let resource: serde_json::Value = serde_json::from_str(&resource_body)
        .map_err(|error| format!("Container App returned invalid JSON: {error}"))?;
    let ready_revision = resource
        .pointer("/properties/latestReadyRevisionName")
        .and_then(serde_json::Value::as_str)
        .ok_or_else(|| "Container App has no ready revision to preserve".to_owned())?;
    let ready_response = http
        .get(format!("{app_uri}/revisions/{ready_revision}"))
        .bearer_auth(access_token)
        .query(&[("api-version", AZURE_MANAGEMENT_API_VERSION)])
        .send()
        .await
        .map_err(|error| format!("could not read ready Container App revision: {error}"))?;
    let ready_status = ready_response.status();
    let ready_body = ready_response
        .text()
        .await
        .map_err(|error| format!("could not read ready revision response: {error}"))?;
    if !ready_status.is_success() {
        return Err(format!(
            "ready revision read returned {ready_status}: {}",
            ready_body.chars().take(300).collect::<String>()
        ));
    }
    let ready_resource: serde_json::Value = serde_json::from_str(&ready_body)
        .map_err(|error| format!("ready revision returned invalid JSON: {error}"))?;
    let ready_image = ready_resource
        .pointer("/properties/template/containers/0/image")
        .and_then(serde_json::Value::as_str)
        .ok_or_else(|| "ready revision has no container image".to_owned())?;
    let patch = production_topology_patch(&resource, ready_image)?;

    let mut last_error = String::new();
    for attempt in 1..=12 {
        let response = http
            .patch(&app_uri)
            .bearer_auth(access_token)
            .query(&[("api-version", AZURE_MANAGEMENT_API_VERSION)])
            .json(&patch)
            .send()
            .await;
        match response {
            Ok(response) if response.status().is_success() => return Ok(()),
            Ok(response) => {
                let status = response.status();
                let retryable =
                    status.as_u16() == 409 || status.as_u16() == 429 || status.is_server_error();
                let body = response.text().await.unwrap_or_default();
                last_error = format!(
                    "Container App repair returned {status}: {}",
                    body.chars().take(300).collect::<String>()
                );
                if !retryable {
                    return Err(last_error);
                }
            }
            Err(error) => last_error = format!("Container App repair request failed: {error}"),
        }
        tokio::time::sleep(Duration::from_secs(attempt * 5)).await;
    }
    Err(last_error)
}

pub fn app(state: AppState) -> Router {
    let governor_conf = GovernorConfigBuilder::default()
        .per_millisecond(50)
        .burst_size(40)
        .key_extractor(SmartIpKeyExtractor)
        .finish()
        .expect("valid rate limit");
    let governor_limiter = governor_conf.limiter().clone();
    tokio::spawn(async move {
        let mut cleanup = tokio::time::interval(Duration::from_secs(60));
        loop {
            cleanup.tick().await;
            governor_limiter.retain_recent();
        }
    });
    // Provisioning a demo performs several durable writes. Keep its admission
    // rate below the single SQLite writer's capacity so a connection burst is
    // rejected immediately instead of waiting behind accepted work. The
    // broader API limiter below still applies to this route as a second bound.
    let demo_governor_conf = GovernorConfigBuilder::default()
        .per_millisecond(1_000)
        .burst_size(20)
        .key_extractor(SmartIpKeyExtractor)
        .finish()
        .expect("valid demo provisioning rate limit");
    let demo_governor_limiter = demo_governor_conf.limiter().clone();
    tokio::spawn(async move {
        let mut cleanup = tokio::time::interval(Duration::from_secs(60));
        loop {
            cleanup.tick().await;
            demo_governor_limiter.retain_recent();
        }
    });
    let demo_api = Router::new()
        .route("/demo", post(routes::create_demo))
        .layer(GovernorLayer::new(demo_governor_conf).error_handler(|_| too_many_requests()));
    let api = Router::new()
        .merge(demo_api)
        .route("/records", post(routes::create_record))
        .route("/records/import", post(routes::import_records))
        .route(
            "/records/{id}/evidence",
            post(routes::add_evidence).delete(routes::remove_evidence),
        )
        .route(
            "/records/{id}",
            axum::routing::delete(routes::delete_record),
        )
        .route("/export", get(routes::export_pack))
        .route(
            "/workspace",
            axum::routing::delete(routes::delete_workspace)
                .post(routes::create_workspace)
                .get(routes::get_workspace),
        )
        .layer(DefaultBodyLimit::max(8 * 1024 * 1024))
        .layer(GovernorLayer::new(governor_conf).error_handler(|_| too_many_requests()));

    let static_dir = env::var("STATIC_DIR").unwrap_or_else(|_| "dist".into());
    let index = PathBuf::from(&static_dir).join("index.html");
    Router::new()
        .route("/health", get(health))
        .nest("/api", api)
        .fallback_service(ServeDir::new(&static_dir).fallback(ServeFile::new(index)))
        .layer(middleware::from_fn(security_headers))
        .layer(CompressionLayer::new())
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}

fn too_many_requests() -> Response {
    let mut response = Response::new(Body::from("Too many requests. Try again in one second."));
    *response.status_mut() = StatusCode::TOO_MANY_REQUESTS;
    response
        .headers_mut()
        .insert(header::RETRY_AFTER, HeaderValue::from_static("1"));
    response
}

async fn health(State(state): State<AppState>) -> impl IntoResponse {
    axum::Json(serde_json::json!({"status":"ok", "build_sha":state.build_sha}))
}

async fn security_headers(request: Request, next: Next) -> Response {
    let path = request.uri().path().to_owned();
    let method = request.method().clone();
    let cache_immutable = path.starts_with("/assets/index-");
    let cache_public = path.starts_with("/assets/") || path.starts_with("/fonts/");
    let mut response = next.run(request).await;
    let known_page = matches!(
        path.as_str(),
        "/" | "/demo" | "/app" | "/privacy" | "/terms"
    );
    if method == axum::http::Method::GET
        && response.status() == StatusCode::OK
        && !known_page
        && !path.starts_with("/api/")
        && !path.starts_with("/assets/")
        && !path.starts_with("/fonts/")
        && !matches!(
            path.as_str(),
            "/health" | "/favicon.svg" | "/apple-touch-icon.png" | "/robots.txt" | "/sitemap.xml"
        )
    {
        *response.status_mut() = StatusCode::NOT_FOUND;
    }
    let headers = response.headers_mut();
    headers.insert(
        "x-content-type-options",
        HeaderValue::from_static("nosniff"),
    );
    headers.insert(
        "referrer-policy",
        HeaderValue::from_static("strict-origin-when-cross-origin"),
    );
    headers.insert(
        "permissions-policy",
        HeaderValue::from_static("camera=(), microphone=(), geolocation=()"),
    );
    headers.insert(
        "strict-transport-security",
        HeaderValue::from_static("max-age=31536000; includeSubDomains"),
    );
    headers.insert("content-security-policy", HeaderValue::from_static("default-src 'self'; img-src 'self' data:; font-src 'self' data:; style-src 'self'; script-src 'self'; connect-src 'self' https://api.sociobot.in; object-src 'none'; base-uri 'self'; form-action 'self' https://api.sociobot.in; frame-ancestors 'none'"));
    headers.insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static(if cache_immutable {
            "public, max-age=31536000, immutable"
        } else if cache_public {
            "public, max-age=3600, must-revalidate"
        } else {
            "no-cache"
        }),
    );
    response
}

async fn shutdown_signal() {
    let ctrl_c = async { signal::ctrl_c().await.expect("install Ctrl+C handler") };
    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("install signal handler")
            .recv()
            .await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! { _ = ctrl_c => {}, _ = terminate => {} }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{body::Body, http::Request};
    use tower::ServiceExt;

    async fn test_app() -> Router {
        let db = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&db).await.unwrap();
        app(AppState {
            db,
            build_sha: "test-sha".into(),
            billing_base: "http://127.0.0.1:9/api/v1".into(),
            http: reqwest::Client::new(),
            write_lock: Arc::new(tokio::sync::Mutex::new(())),
        })
    }

    #[tokio::test]
    async fn health_reports_build_sha() {
        let response = test_app()
            .await
            .oneshot(
                Request::builder()
                    .uri("/health")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        assert_eq!(
            response.headers().get("x-content-type-options").unwrap(),
            "nosniff"
        );
        assert_eq!(
            response.headers().get("strict-transport-security").unwrap(),
            "max-age=31536000; includeSubDomains"
        );
    }

    #[test]
    fn azure_runtime_rejects_the_generic_container_local_filesystem() {
        let mountinfo = "29 23 0:25 / / rw,relatime - overlay overlay rw\n";
        let error = validate_azure_storage_contract("/data", mountinfo, None).unwrap_err();
        assert!(error.contains("no dedicated /data mount"));
    }

    #[test]
    fn azure_runtime_rejects_a_durable_mount_without_the_required_vfs() {
        let mountinfo = concat!(
            "29 23 0:25 / / rw,relatime - overlay overlay rw\n",
            "42 29 0:40 / /data rw,relatime - cifs //account/share rw\n"
        );
        let error = validate_azure_storage_contract("/data", mountinfo, None).unwrap_err();
        assert!(error.contains("SQLITE_VFS=unix-dotfile"));
    }

    #[test]
    fn azure_runtime_accepts_the_durable_data_mount_and_required_vfs() {
        let mountinfo = concat!(
            "29 23 0:25 / / rw,relatime - overlay overlay rw\n",
            "42 29 0:40 / /data rw,relatime - cifs //account/share rw\n"
        );
        validate_azure_storage_contract("/data", mountinfo, Some("unix-dotfile")).unwrap();
    }

    #[test]
    fn verification_16_generic_rollout_is_reconciled_before_it_can_serve() {
        let resource = serde_json::json!({
            "properties": {
                "latestRevisionName": "sf-mtd-evidence-rail--0000054",
                "latestReadyRevisionName": "sf-mtd-evidence-rail--0000053",
                "configuration": {"activeRevisionsMode":"Single"},
                "template": {
                    "containers": [{
                        "name":"app",
                        "image":"sociobotregistry.azurecr.io/sf-mtd-evidence-rail:560392b27a89",
                        "resources":{"cpu":0.5,"memory":"1Gi"},
                        "env":[
                            {"name":"PORT","value":"8080"},
                            {"name":"BUILD_SHA","value":"stale"}
                        ]
                    }],
                    "scale":{"minReplicas":1,"maxReplicas":3},
                    "volumes":null
                }
            }
        });
        let ready_image = "sociobotregistry.azurecr.io/sf-mtd-evidence-rail:5779508e0a5c";
        let patch = production_topology_patch(&resource, ready_image).unwrap();
        assert_eq!(
            patch.pointer("/properties/template/scale/maxReplicas"),
            Some(&serde_json::json!(1))
        );
        assert_eq!(
            patch.pointer("/properties/template/containers/0/image"),
            Some(&serde_json::json!(ready_image))
        );
        assert_eq!(
            patch.pointer("/properties/template/containers/0/volumeMounts/0"),
            Some(&serde_json::json!({"volumeName":"mtd-data","mountPath":"/data"}))
        );
        assert_eq!(
            patch.pointer("/properties/template/volumes/0"),
            Some(&serde_json::json!({
                "name":"mtd-data",
                "storageName":"mtd-evidence-rail-data",
                "storageType":"AzureFile"
            }))
        );
        let environment = patch
            .pointer("/properties/template/containers/0/env")
            .unwrap()
            .as_array()
            .unwrap();
        assert!(environment.iter().any(|entry| entry
            == &serde_json::json!({
                "name":"SQLITE_VFS","value":"unix-dotfile"
            })));
        assert!(!environment.iter().any(|entry| {
            entry.get("name").and_then(serde_json::Value::as_str) == Some("BUILD_SHA")
        }));
    }

    #[tokio::test]
    // @claim:api-rate-limit
    async fn api_rate_limit_returns_retry_after() {
        let service = test_app().await;
        for hop in 0..40 {
            let response = service
                .clone()
                .oneshot(
                    Request::builder()
                        .uri("/api/workspace")
                        .header("x-forwarded-for", format!("203.0.113.8, 10.0.0.{hop}"))
                        .body(Body::empty())
                        .unwrap(),
                )
                .await
                .unwrap();
            assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
        }
        let limited = service
            .clone()
            .oneshot(
                Request::builder()
                    .uri("/api/workspace")
                    .header("x-forwarded-for", "203.0.113.8, 192.0.2.99")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(limited.status(), StatusCode::TOO_MANY_REQUESTS);
        assert_eq!(limited.headers().get(header::RETRY_AFTER).unwrap(), "1");

        let other_client = service
            .oneshot(
                Request::builder()
                    .uri("/api/workspace")
                    .header("x-forwarded-for", "198.51.100.4, 192.0.2.99")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(other_client.status(), StatusCode::UNAUTHORIZED);
    }

    #[tokio::test]
    async fn demo_provisioning_burst_returns_all_200_responses_without_overloading_storage() {
        let service = test_app().await;
        let mut requests = tokio::task::JoinSet::new();
        for _ in 0..200 {
            let service = service.clone();
            requests.spawn(async move {
                service
                    .oneshot(
                        Request::builder()
                            .method("POST")
                            .uri("/api/demo")
                            .header("x-forwarded-for", "198.51.100.9, 10.0.0.1")
                            .body(Body::empty())
                            .unwrap(),
                    )
                    .await
                    .unwrap()
            });
        }

        let mut created = 0;
        let mut limited = 0;
        while let Some(result) = requests.join_next().await {
            let response = result.unwrap();
            match response.status() {
                StatusCode::CREATED => created += 1,
                StatusCode::TOO_MANY_REQUESTS => {
                    limited += 1;
                    assert_eq!(response.headers().get(header::RETRY_AFTER).unwrap(), "1");
                    assert_eq!(
                        response.headers().get("strict-transport-security").unwrap(),
                        "max-age=31536000; includeSubDomains"
                    );
                }
                status => panic!("unexpected demo burst response: {status}"),
            }
        }

        assert_eq!(created + limited, 200);
        assert!(created <= 22, "demo limiter admitted {created} writes");
        assert!(
            limited >= 178,
            "demo limiter rejected only {limited} requests"
        );
    }

    #[tokio::test]
    async fn unknown_page_is_a_real_404_and_unversioned_assets_are_revalidated() {
        let service = test_app().await;
        let missing = service
            .clone()
            .oneshot(
                Request::builder()
                    .uri("/not-a-page")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(missing.status(), StatusCode::NOT_FOUND);

        let hero = service
            .oneshot(
                Request::builder()
                    .uri("/assets/evidence-rail-hero.webp")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            hero.headers().get(header::CACHE_CONTROL).unwrap(),
            "public, max-age=3600, must-revalidate"
        );
    }

    #[tokio::test]
    async fn workspace_deletion_removes_records_evidence_and_audit() {
        let db = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&db).await.unwrap();
        sqlx::query("PRAGMA foreign_keys = ON")
            .execute(&db)
            .await
            .unwrap();
        sqlx::query("INSERT INTO workspaces(id,is_demo,created_at) VALUES('delete-me',0,0)")
            .execute(&db)
            .await
            .unwrap();
        sqlx::query("INSERT INTO records(id,workspace_id,kind,record_date,description,amount_pence,category,source,evidence_name,evidence_mime,evidence_data,created_at,updated_at) VALUES('record','delete-me','expense','2026-04-06','Receipt',100,'Office','manual','receipt.txt','text/plain',X'74657374',0,0)")
            .execute(&db)
            .await
            .unwrap();
        sqlx::query("INSERT INTO audit_log(workspace_id,record_id,action,detail,created_at) VALUES('delete-me','record','evidence_linked','Evidence file linked',0)")
            .execute(&db)
            .await
            .unwrap();

        sqlx::query("DELETE FROM workspaces WHERE id='delete-me'")
            .execute(&db)
            .await
            .unwrap();

        let record_count: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM records WHERE workspace_id='delete-me'")
                .fetch_one(&db)
                .await
                .unwrap();
        let audit_count: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM audit_log WHERE workspace_id='delete-me'")
                .fetch_one(&db)
                .await
                .unwrap();
        assert_eq!(record_count.0, 0);
        assert_eq!(audit_count.0, 0);
    }
}
