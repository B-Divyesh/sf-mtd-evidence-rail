use crate::AppState;
use axum::{
    body::Body,
    extract::{Path, Query, State},
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use base64::Engine;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use std::io::{Cursor, Write};
use time::OffsetDateTime;
use uuid::Uuid;
use zip::{write::SimpleFileOptions, CompressionMethod, ZipWriter};

type ApiResult<T> = Result<T, (StatusCode, Json<serde_json::Value>)>;

#[derive(Debug, Serialize, FromRow)]
pub struct Record {
    id: String,
    kind: String,
    record_date: String,
    description: String,
    amount_pence: i64,
    category: String,
    source: String,
    evidence_name: Option<String>,
    evidence_mime: Option<String>,
    invoice_number: Option<String>,
    created_at: i64,
    updated_at: i64,
}

#[derive(Debug, Deserialize)]
pub struct RecordInput {
    kind: String,
    record_date: String,
    description: String,
    amount_pence: i64,
    category: String,
    source: Option<String>,
    invoice_number: Option<String>,
}

#[derive(Deserialize)]
pub struct ImportInput {
    records: Vec<RecordInput>,
}

#[derive(Deserialize)]
pub struct EvidenceInput {
    name: String,
    mime: String,
    data_base64: String,
}

#[derive(Deserialize, Default)]
pub struct PeriodQuery {
    from: Option<String>,
    to: Option<String>,
}

fn error(status: StatusCode, message: &str) -> (StatusCode, Json<serde_json::Value>) {
    (status, Json(serde_json::json!({ "error": message })))
}

fn workspace(headers: &HeaderMap) -> ApiResult<String> {
    headers
        .get("x-workspace-key")
        .and_then(|v| v.to_str().ok())
        .filter(|v| v.len() >= 32)
        .map(ToString::to_string)
        .ok_or_else(|| {
            error(
                StatusCode::UNAUTHORIZED,
                "This workspace key is missing. Start a workspace again.",
            )
        })
}

fn now() -> i64 {
    OffsetDateTime::now_utc().unix_timestamp()
}

async fn check_workspace(db: &sqlx::SqlitePool, id: &str) -> ApiResult<()> {
    let row: Option<(i64, Option<i64>)> =
        sqlx::query_as("SELECT is_demo, expires_at FROM workspaces WHERE id = ?")
            .bind(id)
            .fetch_optional(db)
            .await
            .map_err(internal)?;
    match row {
        None => Err(error(
            StatusCode::NOT_FOUND,
            "This workspace was not found. Start a new workspace.",
        )),
        Some((1, Some(expiry))) if expiry < now() => Err(error(
            StatusCode::GONE,
            "This demo has expired. Reset the demo to start again.",
        )),
        Some(_) => Ok(()),
    }
}

fn internal<E: std::fmt::Display>(err: E) -> (StatusCode, Json<serde_json::Value>) {
    tracing::error!(error = %err, "request failed");
    error(
        StatusCode::INTERNAL_SERVER_ERROR,
        "The record could not be saved. Try again.",
    )
}

pub async fn create_workspace(State(state): State<AppState>) -> ApiResult<impl IntoResponse> {
    let id = Uuid::new_v4().simple().to_string() + &Uuid::new_v4().simple().to_string();
    sqlx::query("INSERT INTO workspaces(id,is_demo,expires_at,created_at) VALUES(?,0,NULL,?)")
        .bind(&id)
        .bind(now())
        .execute(&state.db)
        .await
        .map_err(internal)?;
    Ok((
        StatusCode::CREATED,
        Json(serde_json::json!({"workspace_id": id})),
    ))
}

pub async fn create_demo(State(state): State<AppState>) -> ApiResult<impl IntoResponse> {
    sqlx::query("DELETE FROM workspaces WHERE is_demo = 1 AND expires_at < ?")
        .bind(now())
        .execute(&state.db)
        .await
        .map_err(internal)?;
    let id = format!(
        "demo:{}{}",
        Uuid::new_v4().simple(),
        Uuid::new_v4().simple()
    );
    let created = now();
    let mut tx = state.db.begin().await.map_err(internal)?;
    sqlx::query("INSERT INTO workspaces(id,is_demo,expires_at,created_at) VALUES(?,1,?,?)")
        .bind(&id)
        .bind(created + 86_400)
        .bind(created)
        .execute(&mut *tx)
        .await
        .map_err(internal)?;
    let samples = [
        (
            "expense",
            "2026-04-08",
            "Stationery from Paper Mill",
            1840,
            "Office",
            "bank",
            Some("paper-mill-receipt.pdf"),
            None,
        ),
        (
            "income",
            "2026-04-15",
            "Spring maths tutoring",
            12000,
            "Tutoring",
            "manual",
            Some("INV-026"),
            Some("invoice-026.pdf"),
        ),
        (
            "expense",
            "2026-05-02",
            "Community hall hire",
            6500,
            "Venue",
            "bank",
            None,
            None,
        ),
        (
            "expense",
            "2026-05-19",
            "Train to client session",
            2780,
            "Travel",
            "bank",
            None,
            None,
        ),
        (
            "income",
            "2026-06-03",
            "After-school club fees",
            24500,
            "Club fees",
            "manual",
            Some("INV-031"),
            Some("invoice-031.pdf"),
        ),
        (
            "expense",
            "2026-06-11",
            "Teaching card supplies",
            3299,
            "Materials",
            "bank",
            Some("teaching-cards.jpg"),
            None,
        ),
    ];
    for (kind, date, description, amount, category, source, marker, extra) in samples {
        let (invoice, evidence) = if kind == "income" {
            (marker, extra)
        } else {
            (extra, marker)
        };
        let evidence_data =
            evidence.map(|name| format!("Sample evidence file for {name}\n").into_bytes());
        sqlx::query("INSERT INTO records(id,workspace_id,kind,record_date,description,amount_pence,category,source,evidence_name,evidence_mime,evidence_data,invoice_number,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
            .bind(Uuid::new_v4().to_string()).bind(&id).bind(kind).bind(date).bind(description).bind(amount)
            .bind(category).bind(source).bind(evidence).bind(evidence.map(|_| "text/plain")).bind(evidence_data)
            .bind(invoice).bind(created).bind(created).execute(&mut *tx).await.map_err(internal)?;
    }
    sqlx::query("INSERT INTO audit_log(workspace_id,record_id,action,detail,created_at) VALUES(?,NULL,'demo_started','Six sample transactions added',?)")
        .bind(&id).bind(created).execute(&mut *tx).await.map_err(internal)?;
    tx.commit().await.map_err(internal)?;
    Ok((
        StatusCode::CREATED,
        Json(serde_json::json!({"workspace_id": id, "expires_in_hours":24})),
    ))
}

pub async fn get_workspace(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(period): Query<PeriodQuery>,
) -> ApiResult<Json<serde_json::Value>> {
    let id = workspace(&headers)?;
    check_workspace(&state.db, &id).await?;
    let from = period.from.unwrap_or_else(|| "0000-01-01".into());
    let to = period.to.unwrap_or_else(|| "9999-12-31".into());
    let records: Vec<Record> = sqlx::query_as("SELECT id,kind,record_date,description,amount_pence,category,source,evidence_name,evidence_mime,invoice_number,created_at,updated_at FROM records WHERE workspace_id=? AND record_date>=? AND record_date<=? ORDER BY record_date DESC, created_at DESC")
        .bind(&id).bind(from).bind(to).fetch_all(&state.db).await.map_err(internal)?;
    let missing = records.iter().filter(|r| r.evidence_name.is_none()).count();
    Ok(Json(
        serde_json::json!({"records":records, "summary":{"total":records.len(),"missing":missing}}),
    ))
}

fn validate(input: &RecordInput) -> ApiResult<()> {
    if !matches!(input.kind.as_str(), "expense" | "income") {
        return Err(error(StatusCode::BAD_REQUEST, "Choose expense or income."));
    }
    if input.record_date.len() != 10
        || input.record_date.as_bytes().get(4) != Some(&b'-')
        || input.record_date.as_bytes().get(7) != Some(&b'-')
    {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Enter the date as YYYY-MM-DD.",
        ));
    }
    if input.description.trim().is_empty() || input.description.chars().count() > 120 {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Enter a description under 120 characters.",
        ));
    }
    if input.amount_pence <= 0 || input.amount_pence > 100_000_000 {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Enter an amount between £0.01 and £1,000,000.",
        ));
    }
    if input.category.trim().is_empty() || input.category.chars().count() > 40 {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Enter a category under 40 characters.",
        ));
    }
    Ok(())
}

async fn insert_record(
    db: &sqlx::SqlitePool,
    workspace_id: &str,
    input: RecordInput,
) -> ApiResult<String> {
    validate(&input)?;
    let id = Uuid::new_v4().to_string();
    let timestamp = now();
    let source = input
        .source
        .as_deref()
        .filter(|s| *s == "bank")
        .unwrap_or("manual");
    sqlx::query("INSERT INTO records(id,workspace_id,kind,record_date,description,amount_pence,category,source,invoice_number,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)")
        .bind(&id).bind(workspace_id).bind(input.kind).bind(input.record_date).bind(input.description.trim())
        .bind(input.amount_pence).bind(input.category.trim()).bind(source).bind(input.invoice_number.filter(|s| !s.trim().is_empty()))
        .bind(timestamp).bind(timestamp).execute(db).await.map_err(internal)?;
    sqlx::query("INSERT INTO audit_log(workspace_id,record_id,action,detail,created_at) VALUES(?,?,'record_created','Transaction added',?)")
        .bind(workspace_id).bind(&id).bind(timestamp).execute(db).await.map_err(internal)?;
    Ok(id)
}

pub async fn create_record(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(input): Json<RecordInput>,
) -> ApiResult<impl IntoResponse> {
    let workspace_id = workspace(&headers)?;
    check_workspace(&state.db, &workspace_id).await?;
    let id = insert_record(&state.db, &workspace_id, input).await?;
    Ok((StatusCode::CREATED, Json(serde_json::json!({"id":id}))))
}

pub async fn import_records(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(input): Json<ImportInput>,
) -> ApiResult<impl IntoResponse> {
    let workspace_id = workspace(&headers)?;
    check_workspace(&state.db, &workspace_id).await?;
    if input.records.is_empty() || input.records.len() > 500 {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Import between 1 and 500 transactions.",
        ));
    }
    let count = input.records.len();
    for record in input.records {
        insert_record(&state.db, &workspace_id, record).await?;
    }
    Ok((
        StatusCode::CREATED,
        Json(serde_json::json!({"imported":count})),
    ))
}

pub async fn add_evidence(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(record_id): Path<String>,
    Json(input): Json<EvidenceInput>,
) -> ApiResult<Json<serde_json::Value>> {
    let workspace_id = workspace(&headers)?;
    check_workspace(&state.db, &workspace_id).await?;
    if input.name.trim().is_empty() || input.name.len() > 180 {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Choose a file with a shorter name.",
        ));
    }
    if !matches!(
        input.mime.as_str(),
        "application/pdf" | "image/jpeg" | "image/png" | "image/webp" | "text/plain"
    ) {
        return Err(error(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            "Use a PDF, JPG, PNG, WebP, or text file.",
        ));
    }
    let data = base64::engine::general_purpose::STANDARD
        .decode(&input.data_base64)
        .map_err(|_| {
            error(
                StatusCode::BAD_REQUEST,
                "The evidence file could not be read. Choose it again.",
            )
        })?;
    if data.is_empty() || data.len() > 5 * 1024 * 1024 {
        return Err(error(
            StatusCode::PAYLOAD_TOO_LARGE,
            "Choose an evidence file under 5 MB.",
        ));
    }
    let result = sqlx::query("UPDATE records SET evidence_name=?,evidence_mime=?,evidence_data=?,updated_at=? WHERE id=? AND workspace_id=?")
        .bind(input.name.trim()).bind(&input.mime).bind(data).bind(now()).bind(&record_id).bind(&workspace_id).execute(&state.db).await.map_err(internal)?;
    if result.rows_affected() == 0 {
        return Err(error(
            StatusCode::NOT_FOUND,
            "This transaction was not found. Reload the page.",
        ));
    }
    sqlx::query("INSERT INTO audit_log(workspace_id,record_id,action,detail,created_at) VALUES(?,?,'evidence_linked','Evidence file linked',?)")
        .bind(&workspace_id).bind(&record_id).bind(now()).execute(&state.db).await.map_err(internal)?;
    Ok(Json(serde_json::json!({"linked":true})))
}

pub async fn remove_evidence(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(record_id): Path<String>,
) -> ApiResult<Json<serde_json::Value>> {
    let workspace_id = workspace(&headers)?;
    check_workspace(&state.db, &workspace_id).await?;
    let result = sqlx::query("UPDATE records SET evidence_name=NULL,evidence_mime=NULL,evidence_data=NULL,updated_at=? WHERE id=? AND workspace_id=?")
        .bind(now()).bind(&record_id).bind(&workspace_id).execute(&state.db).await.map_err(internal)?;
    if result.rows_affected() == 0 {
        return Err(error(
            StatusCode::NOT_FOUND,
            "This transaction was not found. Reload the page.",
        ));
    }
    sqlx::query("INSERT INTO audit_log(workspace_id,record_id,action,detail,created_at) VALUES(?,?,'evidence_removed','Evidence file removed',?)")
        .bind(&workspace_id).bind(&record_id).bind(now()).execute(&state.db).await.map_err(internal)?;
    Ok(Json(serde_json::json!({"linked":false})))
}

pub async fn delete_record(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(record_id): Path<String>,
) -> ApiResult<StatusCode> {
    let workspace_id = workspace(&headers)?;
    check_workspace(&state.db, &workspace_id).await?;
    sqlx::query("DELETE FROM records WHERE id=? AND workspace_id=?")
        .bind(record_id)
        .bind(workspace_id)
        .execute(&state.db)
        .await
        .map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

pub async fn delete_workspace(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> ApiResult<StatusCode> {
    let workspace_id = workspace(&headers)?;
    if headers
        .get("x-confirm-delete")
        .and_then(|v| v.to_str().ok())
        != Some("delete")
    {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "Confirm deletion before removing this workspace.",
        ));
    }
    sqlx::query("DELETE FROM workspaces WHERE id=?")
        .bind(workspace_id)
        .execute(&state.db)
        .await
        .map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

#[derive(FromRow)]
struct ExportRecord {
    id: String,
    kind: String,
    record_date: String,
    description: String,
    amount_pence: i64,
    category: String,
    source: String,
    evidence_name: Option<String>,
    evidence_data: Option<Vec<u8>>,
    invoice_number: Option<String>,
}

pub async fn export_pack(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(period): Query<PeriodQuery>,
) -> ApiResult<Response> {
    let workspace_id = workspace(&headers)?;
    check_workspace(&state.db, &workspace_id).await?;
    let from = period.from.unwrap_or_else(|| "0000-01-01".into());
    let to = period.to.unwrap_or_else(|| "9999-12-31".into());
    let records: Vec<ExportRecord> = sqlx::query_as("SELECT id,kind,record_date,description,amount_pence,category,source,evidence_name,evidence_data,invoice_number FROM records WHERE workspace_id=? AND record_date>=? AND record_date<=? ORDER BY record_date")
        .bind(&workspace_id).bind(&from).bind(&to).fetch_all(&state.db).await.map_err(internal)?;
    if records.is_empty() {
        return Err(error(
            StatusCode::BAD_REQUEST,
            "This quarter has no transactions to export.",
        ));
    }
    let mut csv_bytes = Vec::new();
    {
        let mut writer = csv::Writer::from_writer(&mut csv_bytes);
        writer
            .write_record([
                "date",
                "type",
                "description",
                "amount_gbp",
                "category",
                "source",
                "invoice_number",
                "evidence_file",
                "evidence_status",
            ])
            .map_err(internal)?;
        for r in &records {
            let amount = format!("{:.2}", r.amount_pence as f64 / 100.0);
            writer
                .write_record([
                    r.record_date.as_str(),
                    r.kind.as_str(),
                    r.description.as_str(),
                    amount.as_str(),
                    r.category.as_str(),
                    r.source.as_str(),
                    r.invoice_number.as_deref().unwrap_or(""),
                    r.evidence_name.as_deref().unwrap_or(""),
                    if r.evidence_name.is_some() {
                        "linked"
                    } else {
                        "missing"
                    },
                ])
                .map_err(internal)?;
        }
        writer.flush().map_err(internal)?;
    }
    let cursor = Cursor::new(Vec::new());
    let mut zip = ZipWriter::new(cursor);
    let options = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    zip.start_file("transactions.csv", options)
        .map_err(internal)?;
    zip.write_all(&csv_bytes).map_err(internal)?;
    zip.start_file("README.txt", options).map_err(internal)?;
    zip.write_all(b"MTD Evidence Rail evidence pack\n\nReview missing rows in transactions.csv before sharing. This pack is a record aid, not an HMRC filing or tax calculation.\n").map_err(internal)?;
    for r in &records {
        if let (Some(name), Some(data)) = (&r.evidence_name, &r.evidence_data) {
            let safe_name: String = name
                .chars()
                .map(|c| {
                    if c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_') {
                        c
                    } else {
                        '_'
                    }
                })
                .collect();
            zip.start_file(format!("evidence/{}_{}", r.id, safe_name), options)
                .map_err(internal)?;
            zip.write_all(data).map_err(internal)?;
        }
    }
    let bytes = zip.finish().map_err(internal)?.into_inner();
    let mut response = Response::new(Body::from(bytes));
    response.headers_mut().insert(
        header::CONTENT_TYPE,
        HeaderValue::from_static("application/zip"),
    );
    response.headers_mut().insert(
        header::CONTENT_DISPOSITION,
        HeaderValue::from_str(&format!(
            "attachment; filename=\"evidence-pack-{}-to-{}.zip\"",
            from, to
        ))
        .unwrap(),
    );
    Ok(response)
}
