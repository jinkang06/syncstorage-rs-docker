#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
sleep 10
# --- Wait for MariaDB to be ready ---
echo "Waiting for database connection at ${DB_HOST}:${DB_PORT}..."
# Loop until the mysqladmin command succeeds
# The -i1 option is not available in all mysqladmin versions, so we use sleep.
while ! mysqladmin ping -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" --silent; do
    echo "Database is unavailable - sleeping"
    sleep 2
done
echo "Database is up!"

# --- Run Migrations ---
echo "Running syncstorage database migrations..."
/usr/local/cargo/bin/diesel --database-url "${SYNC_SYNCSTORAGE_DATABASE_URL}" migration --migration-dir syncstorage-mysql/migrations run

echo "Running tokenserver database migrations..."
/usr/local/cargo/bin/diesel --database-url "${SYNC_TOKENSERVER_DATABASE_URL}" migration --migration-dir tokenserver-db/migrations run
echo "Migrations complete."

# --- Configure TokenServer Nodes ---
# This ensures the tokenserver knows where to direct users.
# We use environment variables directly, avoiding fragile string parsing.
echo "Configuring tokenserver nodes..."
mysql "${DB_TOKENSERVER_NAME}" -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" <<EOF
DELETE FROM services;
INSERT INTO services (id, service, pattern) VALUES
    (1, "sync-1.5", "{node}/1.5/{uid}");
REPLACE INTO nodes (id, service, node, capacity, available, current_load, downed, backoff) VALUES
    (1, 1, "${SYNC_URL}", ${SYNC_CAPACITY}, ${SYNC_CAPACITY}, 0, 0, 0);
EOF
echo "TokenServer nodes configured."

# --- Write Config File ---
echo "Generating syncserver config file at /config/local.toml"
cat > /config/local.toml <<EOF
master_secret = "${SYNC_MASTER_SECRET}"
human_logs = 1
host = "0.0.0.0"
port = 8000
syncstorage.database_url = "${SYNC_SYNCSTORAGE_DATABASE_URL}"
syncstorage.enable_quota = 0
syncstorage.enabled = true
tokenserver.database_url = "${SYNC_TOKENSERVER_DATABASE_URL}"
tokenserver.enabled = true
tokenserver.fxa_email_domain = "api.accounts.firefox.com"
tokenserver.fxa_metrics_hash_secret = "${METRICS_HASH_SECRET}"
tokenserver.fxa_oauth_server_url = "https://oauth.accounts.firefox.com"
tokenserver.fxa_browserid_audience = "https://token.services.mozilla.com"
tokenserver.fxa_browserid_issuer = "https://api.accounts.firefox.com"
tokenserver.fxa_browserid_server_url = "https://verifier.accounts.firefox.com/v2"
EOF

# --- Start the Server ---
# Use exec to replace the shell process with the server process
LOGLEVEL=${LOGLEVEL:-warn} # Set default loglevel if not provided
echo "Starting syncserver with log level: ${LOGLEVEL}"
source /app/venv/bin/activate


export RUST_LOG=$LOGLEVEL
exec /usr/local/cargo/bin/syncserver --config /config/local.toml
