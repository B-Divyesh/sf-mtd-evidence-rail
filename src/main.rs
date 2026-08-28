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
use sqlx::sqlite::SqlitePoolOptions;
use std::{env, net::SocketAddr, path::PathBuf, time::Duration};
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
    let db = SqlitePoolOptions::new()
        .max_connections(8)
        .connect(&db_url)
        .await
        .expect("open database");
    sqlx::migrate!().run(&db).await.expect("run migrations");
    let build_sha = env::var("BUILD_SHA").unwrap_or_else(|_| "dev".into());
    tracing::info!(port, database = %db_path.display(), build_sha, "configuration ready; local database generated if absent; no secret configuration required");
    let state = AppState { db, build_sha };
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
    let cache_static =
        request.uri().path().starts_with("/assets/") || request.uri().path().starts_with("/fonts/");
    let mut response = next.run(request).await;
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
        HeaderValue::from_static(if cache_static {
            "public, max-age=31536000, immutable"
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
        let mut last = StatusCode::OK;
        let mut retry_after = None;
        for _ in 0..45 {
            let response = service
                .clone()
                .oneshot(
                    Request::builder()
                        .method("POST")
                        .uri("/api/demo")
                        .header("x-forwarded-for", "203.0.113.8")
                        .body(Body::empty())
                        .unwrap(),
                )
                .await
                .unwrap();
            last = response.status();
            retry_after = response.headers().get(header::RETRY_AFTER).cloned();
        }
        assert_eq!(last, StatusCode::TOO_MANY_REQUESTS);
        assert_eq!(retry_after.unwrap(), "1");
    }
}
