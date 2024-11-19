# chef stage
FROM lukemathwalker/cargo-chef:latest AS chef
WORKDIR /app
RUN apt update && apt install lld clang -y

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# builder stage
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# build our project dependencies, not our application!
RUN cargo chef cook --release --recipe-path recipe.json
# Up to this point, if our dependencies are not changing, we can cache them!
COPY . .
ENV SQLX_OFFLINE=true
RUN cargo build --release --bin newsletter

# Runtime stage
FROM debian:bookworm-slim AS runtime
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
