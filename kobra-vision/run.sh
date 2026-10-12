#!/usr/bin/env bash
set -e
echo "[INFO] Starting Kobra Vision add-on..."

# Turn every add-on option into an environment variable the service understands
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

export HTTP_HOST=0.0.0.0
export HTTP_PORT=7917

if [ -n "${VISION_TOKEN:-}" ]; then
    echo "[INFO] VISION_TOKEN is set: the bridge needs the same token"
fi

cd /app
exec python -m kobravision
