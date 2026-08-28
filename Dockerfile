FROM node:22-alpine AS frontend-builder
WORKDIR /build
COPY package.json package-lock.json tsconfig.json vite.config.ts ./
COPY frontend ./frontend
RUN npm ci && npm run build

FROM rust:1.88-bookworm AS backend-builder
WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY migrations ./migrations
COPY src ./src
RUN cargo build --release --locked

FROM debian:bookworm-slim AS runtime
ARG BUILD_SHA=dev
ENV BUILD_SHA=${BUILD_SHA} PORT=8080 DATA_DIR=/data STATIC_DIR=/app/dist
RUN useradd --system --uid 10001 --create-home rail && mkdir -p /data /app/dist && chown -R rail:rail /data /app
COPY --from=backend-builder /build/target/release/mtd-evidence-rail /usr/local/bin/mtd-evidence-rail
COPY --from=frontend-builder /build/dist /app/dist
USER rail
EXPOSE 8080
CMD ["/usr/local/bin/mtd-evidence-rail"]
