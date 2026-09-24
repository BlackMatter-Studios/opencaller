# Multi-stage Dockerfile for OpenCaller API
# Resulting container consumes ~15-25 MB of RAM

# Build stage
FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Cargo.toml Cargo.lock* ./

# Build dependencies dummy cache
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release || true
RUN rm -rf src

# Copy real source code and force binary rebuild
COPY src ./src
RUN rm -f target/release/deps/opencaller* target/release/opencaller*
RUN cargo build --release
RUN strip target/release/opencaller-api

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -U -s /bin/sh opencaller

USER opencaller
WORKDIR /home/opencaller

COPY --from=builder /app/target/release/opencaller-api /usr/local/bin/opencaller-api

EXPOSE 8080
ENV PORT=8080
ENV HOST=0.0.0.0

CMD ["opencaller-api"]
