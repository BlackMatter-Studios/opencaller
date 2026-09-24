# Multi-stage Dockerfile for OpenCaller Crawler Daemon
# Memory footprint: ~15 MB RAM

FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Cargo.toml Cargo.lock* ./

RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release || true
RUN rm -rf src

COPY src ./src
RUN rm -f target/release/deps/opencaller* target/release/opencaller*
RUN cargo build --release
RUN strip target/release/opencaller-crawler

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -U -s /bin/sh opencaller

USER opencaller
WORKDIR /home/opencaller

COPY --from=builder /app/target/release/opencaller-crawler /usr/local/bin/opencaller-crawler

CMD ["opencaller-crawler"]
