# Stage 1: Builder
# Use a Rust version new enough for dependencies, based on "bookworm" OS
FROM rust:1.90-bookworm AS builder

ARG GIT_COMMIT=1dc421474df2a4ee973d529534cd0eb7189d58ce

WORKDIR /app

# Install build-time dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-virtualenv \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build the project
RUN git clone https://github.com/mozilla-services/syncstorage-rs ./ \
    && git reset --hard ${GIT_COMMIT} \
    && cargo install --path ./syncserver --no-default-features --features=syncstorage-db/mysql --locked \
    && cargo install diesel_cli --no-default-features --features 'mysql'

# Setup the Python venv
RUN virtualenv venv \
    && /app/venv/bin/pip install -r requirements.txt \
    && /app/venv/bin/pip install -r tools/tokenserver/requirements.txt \
    && /app/venv/bin/pip install pyopenssl==22.1.0

# ---

# Stage 2: Final Image
# Use the FULL "bookworm" OS base, NOT slim
FROM debian:bookworm

# Create non-root user for security
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid 1000 --shell /bin/bash --create-home appuser

# Install runtime dependencies, explicitly adding libcurl4
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client \
    python3 \
    python3-venv \
    libpython3.11 \
    libcurl4 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ldconfig

# Create needed directories and set permissions
RUN mkdir -p /app /config && chown -R appuser:appuser /app /config
WORKDIR /app
USER appuser

# Copy compiled artifacts and necessary files from the builder stage
COPY --from=builder /usr/local/cargo/bin/syncserver /usr/local/cargo/bin/
COPY --from=builder /usr/local/cargo/bin/diesel /usr/local/cargo/bin/
COPY --from=builder /app/syncstorage-mysql/migrations ./syncstorage-mysql/migrations
COPY --from=builder /app/tokenserver-db/migrations ./tokenserver-db/migrations
COPY --from=builder /app/venv ./venv

# Copy entrypoint script, set permissions, and define it as the entrypoint
COPY --chown=appuser:appuser --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
