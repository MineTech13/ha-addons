"""Find the Spoolman and Kobra Vision add-ons from this repository.

Prints shell `export` lines for SPOOLMAN_URL / VISION_URL when they are empty
and the matching add-on is installed. An address set in the options always wins.
Add-ons from one repository share the slug prefix (<repo hash>_), so the other
add-ons are looked up by name through the Supervisor API (info calls only).
Never fails: without Supervisor access nothing is detected.
"""
import json
import os
import shlex
import sys
import urllib.request

SELF = "ace_lane_bridge"
# option -> (add-on slug, internal port, health path)
TARGETS = {
    "SPOOLMAN_URL": ("spoolman_hybrid", 7912, "/api/v1/info"),
    "VISION_URL": ("kobra_vision", 7917, "/v1/health"),
}
# Placeholder that versions up to 3.12.0-2 shipped as the SPOOLMAN_URL default
OLD_PLACEHOLDER = "http://192.168.1.10:7912"


def log(msg):
    print("[INFO] Autodetect: " + msg, file=sys.stderr)


def addon_info(slug):
    token = os.environ.get("SUPERVISOR_TOKEN")
    if not token:
        return None
    req = urllib.request.Request(
        "http://supervisor/addons/%s/info" % slug, headers={"Authorization": "Bearer " + token}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            return json.load(r).get("data") or None
    except Exception:
        return None


def reachable(url):
    try:
        urllib.request.urlopen(url, timeout=3).close()
        return True
    except Exception:
        return False


def main():
    wanted = [k for k in TARGETS if not os.environ.get(k)]
    if os.environ.get("SPOOLMAN_URL") == OLD_PLACEHOLDER:
        log("SPOOLMAN_URL is still the old example address, trying to detect it")
        wanted.insert(0, "SPOOLMAN_URL")
    if not wanted:
        return

    me = addon_info("self")
    slug = (me or {}).get("slug", "")
    if not slug.endswith(SELF):
        log("Supervisor API not available, set %s by hand" % " / ".join(wanted))
        return
    prefix = slug[: -len(SELF)]

    for key in wanted:
        target, port, health = TARGETS[key]
        info = addon_info(prefix + target)
        # Not installed add-ons of the repository come back from the store with state "unknown"
        if not info or not info.get("hostname") or info.get("installed") is False or info.get("state") == "unknown":
            log("%s: add-on %s not installed" % (key, target))
            continue
        url = "http://%s:%d" % (info["hostname"], port)
        print("export %s=%s" % (key, shlex.quote(url)))
        log("%s = %s (add-on %s, %s)" % (key, url, info.get("name", target), info.get("state", "?")))
        if info.get("state") != "started":
            log("%s: the add-on is not running yet, the bridge keeps retrying" % key)
        elif not reachable(url + health):
            hint = " (Spoolman's ACCESS_MODE must be 'both' or 'direct')" if key == "SPOOLMAN_URL" else ""
            log("%s: %s does not answer yet%s" % (key, url, hint))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never block the add-on start
        log("failed: %s" % e)
