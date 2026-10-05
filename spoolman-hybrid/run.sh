#!/usr/bin/env bash
set -e
echo "[INFO] Starting Spoolman (Ingress + Direct API) add-on..."

CONFIG_DIR="/config"

# Read an add-on option (python3 ships with the Spoolman image)
opt() {
    python3 -c '
import json, sys
try:
    v = json.load(open("/data/options.json")).get(sys.argv[1], sys.argv[2])
except Exception:
    v = sys.argv[2]
print(str(v).lower() if isinstance(v, bool) else v)
' "$1" "$2"
}

export SPOOLMAN_DEBUG_MODE="$(opt SPOOLMAN_DEBUG_MODE false)"
echo "[INFO] Debug mode: ${SPOOLMAN_DEBUG_MODE}"

if [ "$(opt SPOOLMAN_LEGACY_CLIENT false)" = "true" ]; then
    export SPOOLMAN_LEGACY_CLIENT=TRUE
    echo "[INFO] Using legacy client"
fi

SPOOLMAN_CORS_ORIGIN="$(opt SPOOLMAN_CORS_ORIGIN "")"
if [ -n "$SPOOLMAN_CORS_ORIGIN" ]; then
    export SPOOLMAN_CORS_ORIGIN
    echo "[INFO] CORS origin set to: ${SPOOLMAN_CORS_ORIGIN}"
fi
ACCESS_MODE="$(opt ACCESS_MODE both)"
DIRECT_API_ONLY="$(opt DIRECT_API_ONLY true)"
echo "[INFO] Access mode: ${ACCESS_MODE}"

export SPOOLMAN_DIR_DATA="$CONFIG_DIR"
export SPOOLMAN_DIR_BACKUPS="$CONFIG_DIR/backups"
export SPOOLMAN_DIR_LOGS="$CONFIG_DIR/logs"
export SPOOLMAN_DIR_CACHE="$CONFIG_DIR/cache"

mkdir -p "$SPOOLMAN_DIR_DATA" "$SPOOLMAN_DIR_BACKUPS" "$SPOOLMAN_DIR_LOGS" "$SPOOLMAN_DIR_CACHE"
chown -R 1000:1000 "$CONFIG_DIR" || echo "[WARN] Could not change owner (possibly already correct)"
chmod -R 755 "$CONFIG_DIR" || echo "[WARN] Could not change permissions (possibly already correct)"

if [ -z "${TZ}" ]; then
    export TZ="UTC"
    echo "[INFO] No TZ provided by HA, defaulting to: ${TZ}"
fi
echo "[INFO] Timezone: ${TZ}"

# Spoolman listens on internal port 7913; nginx fronts it.
export SPOOLMAN_PORT=7913

# Ingress needs Spoolman to run under the ingress path; direct-only runs at root.
BASE_PATH=""
if [ "$ACCESS_MODE" != "direct" ]; then
    if [ -z "$SUPERVISOR_TOKEN" ]; then
        echo "[ERROR] SUPERVISOR_TOKEN missing - cannot determine ingress path"
        exit 1
    fi
    echo "[INFO] Querying Supervisor API for ingress URL..."
    INGRESS_URL=$(curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        http://supervisor/addons/self/info \
        | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('ingress_url', ''))" 2>/dev/null || echo "")
    if [ -z "$INGRESS_URL" ]; then
        echo "[ERROR] Could not determine ingress URL"
        exit 1
    fi
    BASE_PATH="${INGRESS_URL%/}"
    export SPOOLMAN_BASE_PATH="$BASE_PATH"
    echo "[INFO] SPOOLMAN_BASE_PATH set to: ${SPOOLMAN_BASE_PATH}"
fi

# proxy_block <rewrite-prefix>: location body proxying to Spoolman
proxy_body() {
    [ -n "$1" ] && echo "        rewrite ^(.*)\$ $1\$1 break;"
    cat <<CONF
        proxy_pass http://127.0.0.1:7913;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 300s;
        proxy_buffering off;
CONF
}

{
    cat <<'CONF'
worker_processes 1;
error_log /dev/stdout info;
pid /tmp/nginx.pid;
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log off;
    client_max_body_size 10m;
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }
CONF

    # Ingress listener (always present: HA always shows the sidebar panel)
    echo "    server {"
    echo "        listen 8099;"
    echo "        allow 172.30.32.2;"
    echo "        deny all;"
    if [ "$ACCESS_MODE" = "direct" ]; then
        cat <<'CONF'
        location / {
            default_type text/plain;
            return 200 "Ingress is disabled (access mode: direct). Open Spoolman on the direct port, or change ACCESS_MODE in the add-on configuration.\n";
        }
CONF
    else
        echo "        location / {"
        proxy_body "$BASE_PATH"
        echo "        }"
    fi
    echo "    }"

    # Direct listener
    if [ "$ACCESS_MODE" != "ingress" ]; then
        echo "    server {"
        echo "        listen 7912;"
        if [ "$ACCESS_MODE" = "direct" ]; then
            # Spoolman at root: full UI + API
            echo "        location / {"
            proxy_body ""
            echo "        }"
            echo "[INFO] Direct port 7912: full web UI and API" >&2
        elif [ "$DIRECT_API_ONLY" = "true" ]; then
            cat <<'CONF'
        location = / {
            default_type text/plain;
            return 200 "Spoolman API is available at /api/v1/. Use Home Assistant Ingress for the web UI.\n";
        }
CONF
            echo "        location /api/ {"
            proxy_body "$BASE_PATH"
            echo "        }"
            echo "[INFO] Direct port 7912: API only (/api/)" >&2
        else
            echo "        location / {"
            proxy_body "$BASE_PATH"
            echo "        }"
            echo "[INFO] Direct port 7912: full proxy (web UI may not render fully, use Ingress)" >&2
        fi
        echo "    }"
    else
        echo "[INFO] Direct port 7912: disabled" >&2
    fi
    echo "}"
} > /etc/nginx/nginx.conf

nginx -t -c /etc/nginx/nginx.conf
nginx -c /etc/nginx/nginx.conf
echo "[INFO] nginx started."

echo "[INFO] Launching Spoolman..."
if [ -x /entrypoint.sh ]; then
    exec /entrypoint.sh
elif [ -x /docker-entrypoint.sh ]; then
    exec /docker-entrypoint.sh
else
    exec uvicorn spoolman.main:app --host 127.0.0.1 --port 7913 --workers 1 --log-level info --no-access-log
fi
