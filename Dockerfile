# builder stage
FROM rust as builder

WORKDIR /app
RUN apt update && apt install lld clang -y
COPY . .
ENV SQLX_OFFLINE=true
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim as runtime
WORKDIR /app
# Install openSSL, ca-certs
RUN apt-get udpate -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    ## clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/newsletter newsletter
COPY configuration configuration
ENV APP_ENVIRONMENT=production

ENTRYPOINT ["./newsletter"]

# Development stage
FROM debian:bookworm-slim as development
WORKDIR /app
# Install openSSL, ca-certs
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    ## clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/newsletter newsletter
COPY configuration configuration
ENV APP_ENVIRONMENT=production

ENTRYPOINT ["./newsletter"]
