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
use std::{env, net::SocketAddr, path::PathBuf, sync::Arc, time::Duration};
use tokio::{net::TcpListener, signal};
use tower_governor::{
    governor::GovernorConfigBuilder, key_extractor::SmartIpKeyExtractor, GovernorLayer,
};
use tower_http::{
    compression::CompressionLayer,
    services::{ServeDir, ServeFile},
    trace::TraceLayer,
};

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
    std::fs::create_dir_all(&data_dir).expect("create data directory");
    let db_path = PathBuf::from(&data_dir).join("evidence-rail.sqlite");
    let db_url = format!("sqlite://{}?mode=rwc", db_path.display());
    let mut connect_options: SqliteConnectOptions = db_url
        .parse::<SqliteConnectOptions>()
        .expect("valid database path")
        .foreign_keys(true)
        .busy_timeout(Duration::from_secs(10));
    let sqlite_vfs = env::var("SQLITE_VFS").ok();
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
    let api = Router::new()
        .route("/demo", post(routes::create_demo))
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
        .layer(GovernorLayer::new(governor_conf).error_handler(|_| {
            let mut response =
                Response::new(Body::from("Too many requests. Try again in one second."));
            *response.status_mut() = StatusCode::TOO_MANY_REQUESTS;
            response
                .headers_mut()
                .insert(header::RETRY_AFTER, HeaderValue::from_static("1"));
            response
        }));

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
    }

    #[tokio::test]
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
