#!/usr/bin/env bash
set -e
echo "[INFO] Starting ACE Lane Bridge add-on..."

# Turn every add-on option into an environment variable the bridge understands
eval "$(python -c '
import json, shlex
try:
    opts = json.load(open("/data/options.json"))
except Exception:
    opts = {}
for k, v in opts.items():
    if v is None or v == "":
        continue
    v = str(v).lower() if isinstance(v, bool) else str(v)
    print("export %s=%s" % (k, shlex.quote(v)))
')"

# State lives in the add-on config folder (visible as /addon_configs/<slug>/).
# Older versions kept it in the hidden /data folder: copy it over once.
export DATA_DIR=/config
mkdir -p "$DATA_DIR"
if [ ! -e "$DATA_DIR/.migrated-from-data" ]; then
    if [ -z "$(ls -A "$DATA_DIR")" ] && [ -n "$(find /data -mindepth 1 -maxdepth 1 ! -name options.json -print -quit)" ]; then
        echo "[INFO] Migrating existing state from /data to $DATA_DIR..."
        find /data -mindepth 1 -maxdepth 1 ! -name options.json -exec cp -a {} "$DATA_DIR"/ \;
    fi
    touch "$DATA_DIR/.migrated-from-data"
fi
export HTTP_HOST=0.0.0.0
export HTTP_PORT=7913
[ -n "$TZ" ] || export TZ=UTC

echo "[INFO] Moonraker: ${MOONRAKER_URL}"
echo "[INFO] Spoolman:  ${SPOOLMAN_URL}"
echo "[INFO] Dry run:   ${DRY_RUN:-false}"

# Optional: run upstream's Spoolman setup (extra fields + template filaments).
# Create-only and idempotent, never fatal for the add-on.
if [ "${RUN_SPOOLMAN_SETUP:-false}" = "true" ]; then
    echo "[INFO] RUN_SPOOLMAN_SETUP is on - waiting for Spoolman at ${SPOOLMAN_URL}..."
    READY=0
    for _ in $(seq 1 30); do
        if python -c 'import sys, urllib.request; urllib.request.urlopen(sys.argv[1].rstrip("/") + "/api/v1/info", timeout=3)' "$SPOOLMAN_URL" 2>/dev/null; then
            READY=1
            break
        fi
        sleep 2
    done
    if [ "$READY" = "1" ]; then
        python /opt/spoolman_setup.py --yes --url "$SPOOLMAN_URL" \
            || echo "[WARN] Spoolman setup script failed (see output above), continuing"
    else
        echo "[WARN] Spoolman not reachable after 60s, skipping setup. Check SPOOLMAN_URL."
    fi
fi

# Make API calls relative so the UI works under the HA ingress path
# (2.5.0 had one inline index.html; 2.6+ has js/api.js - both contain fetch(path, ...))
PATCHED=0
while IFS= read -r -d '' f; do
    if grep -qE 'fetch\(path, ' "$f"; then
        sed -i -E 's#fetch\(path, #fetch(path.replace(/^[/]/, ""), #; s#href="/api/#href="api/#g' "$f"
        echo "[INFO] Patched web UI for ingress: $f"
        PATCHED=1
    fi
done < <(find /app -path '*static*' -type f \( -name '*.html' -o -name '*.js' \) -print0 2>/dev/null)
[ "$PATCHED" = "1" ] || echo "[WARN] Could not patch the web UI - the ingress page may not work"

cd /app
exec python -m acebridge
