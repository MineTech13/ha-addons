#!/usr/bin/env python3
"""Small fixes to the bridge web UI. Since upstream 3.13 the UI works behind Home Assistant ingress on its own; only
what upstream does not cover is left here. Each patch is optional: a missing anchor (upstream changed the code) only
prints a warning."""
import pathlib

STATIC = pathlib.Path("/app/acebridge/static/js")


def patch(path, old, new, label, done_marker=None):
    p = STATIC / path
    try:
        s = p.read_text()
    except OSError:
        print(f"[WARN] {label}: {path} not found, skipped")
        return
    if done_marker and done_marker in s:
        print(f"[INFO] {label}: already patched")
        return
    if old not in s:
        print(f"[WARN] {label}: anchor not found in {path} (upstream changed?), skipped")
        return
    p.write_text(s.replace(old, new, 1))
    print(f"[INFO] {label}: patched {path}")


# 1. Direct address under ingress (camera links, app pairing QR code) when BRIDGE_PUBLIC_URL is empty: upstream keeps
#    the protocol HA was opened with, so HA on https gives https://<host>:7913. The bridge port has no TLS: use http.
patch(
    "api.js",
    "`${location.protocol}//${location.hostname}:",
    "`http://${location.hostname}:",
    "direct address uses http",
    done_marker="`http://${location.hostname}:",
)
