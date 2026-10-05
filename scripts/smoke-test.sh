#!/usr/bin/env bash
# Build an add-on and check it starts. Usage: scripts/smoke-test.sh <addon-dir>
set -euo pipefail
cd "$(dirname "$0")/.."
ADDON="${1:?usage: $0 <addon-dir>}"
TAG="smoke-$ADDON"
NAME="smoke-$ADDON-$$"
OPTS="$(mktemp)"
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true; rm -f "$OPTS"' EXIT

docker build -t "$TAG" "$ADDON"

wait_http() { # url, seconds
    for _ in $(seq 1 "$2"); do
        curl -fsS -o /dev/null "$1" 2>/dev/null && return 0
        sleep 1
    done
    return 1
}
fail() { echo "SMOKE TEST FAILED: $*" >&2; docker logs "$NAME" 2>&1 | tail -40 >&2; exit 1; }

case "$ADDON" in
    spoolman-hybrid)
        echo '{"ACCESS_MODE":"direct","DIRECT_API_ONLY":true}' > "$OPTS"
        docker run -d --name "$NAME" -v "$OPTS:/data/options.json:ro" -p 17912:7912 "$TAG" >/dev/null
        wait_http http://127.0.0.1:17912/api/v1/health 90 || fail "Spoolman health check"
        ;;
    ace-lane-bridge)
        echo '{"MOONRAKER_URL":"http://127.0.0.1:7125","SPOOLMAN_URL":"http://127.0.0.1:7912","DRY_RUN":true}' > "$OPTS"
        docker run --rm --entrypoint python "$TAG" /opt/spoolman_setup.py --help >/dev/null \
            || { echo "SMOKE TEST FAILED: spoolman_setup.py missing" >&2; exit 1; }
        docker run -d --name "$NAME" -v "$OPTS:/data/options.json:ro" -p 17913:7913 "$TAG" >/dev/null
        wait_http http://127.0.0.1:17913/ 60 || fail "web UI not reachable"
        LOGS="$(docker logs "$NAME" 2>&1)"
        grep -q 'Patched web UI for ingress' <<<"$LOGS" || fail "ingress UI patch did not apply (upstream layout changed)"
        ;;
    *)
        echo "no smoke test defined for $ADDON, build only" >&2
        ;;
esac
echo "smoke test OK: $ADDON"
