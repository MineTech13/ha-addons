#!/usr/bin/env python3
"""Patch the bridge web UI for use behind Home Assistant ingress. Each patch is optional:
a missing anchor (upstream changed the code) only prints a warning."""
import os
import pathlib

STATIC = pathlib.Path("/app/acebridge/static/js")
INGRESS = 'location.pathname.includes("/api/hassio_ingress/")'


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


# 1. Camera under ingress: the endless MJPEG stream is not passed through reliably by the ingress proxy chain
#    (stream starts, no image arrives). Fetch single frames one after the other instead.
if os.environ.get("INGRESS_CAMERA_SNAPSHOTS", "true") == "true":
    patch(
        "media.js",
        "  const src = on && key ? cameraUrl(key) + `&v=${retry}` : null;\n",
        f"""  const ING = {INGRESS};
  const [snap, setSnap] = useState(null);
  useEffect(() => {{          // ingress: einzelne Bilder nacheinander holen statt MJPEG-Stream
    if (!ING || !on || !key) return;
    let stop = false, timer = null, prev = null;
    const loop = async () => {{
      let wait = 250;
      try {{
        const r = await fetch(cameraUrl(key, "snapshot.jpg") + `&t=${{Date.now()}}`, {{ cache: "no-store" }});
        if (!r.ok) throw new Error(String(r.status));
        const u = URL.createObjectURL(await r.blob());
        if (stop) URL.revokeObjectURL(u);
        else {{ setSnap(u); setErr(null); if (prev) URL.revokeObjectURL(prev); prev = u; }}
      }} catch {{ if (!stop) setErr("Kamera nicht erreichbar – neuer Versuch …"); wait = 3000; }}
      if (!stop) timer = setTimeout(loop, wait);
    }};
    loop();
    return () => {{ stop = true; clearTimeout(timer); if (prev) URL.revokeObjectURL(prev); setSnap(null); }};
  }}, [ING, on, key]);
  const src = on && key ? (ING ? snap : cameraUrl(key) + `&v=${{retry}}`) : null;
""",
        "camera snapshots under ingress",
        done_marker="const ING =",
    )

# 2. Copyable camera links (for Mainsail etc.) must not carry the ingress path: it needs a logged-in HA session.
public = os.environ.get("BRIDGE_PUBLIC_URL", "").strip().rstrip("/")
base = repr(public) if public else '`http://${location.hostname}:7913`'
helper = f"""
/** Links zum Kopieren: unter Ingress die direkte Adresse der Bridge (der Ingress-Pfad braucht eine HA-Anmeldung). */
const pubUrl = (u) => {{
  if (!{INGRESS}) return u;
  const base = {base};
  return u.replace(/^.*?(\\/api\\/camera\\/)/, base + "$1");
}};
"""
patch("pages.js", 'url=${cameraUrl(key)} />', 'url=${pubUrl(cameraUrl(key))} />', "camera link (stream)")
patch("pages.js", 'url=${cameraUrl(key, "snapshot.jpg")} />', 'url=${pubUrl(cameraUrl(key, "snapshot.jpg"))} />', "camera link (snapshot)")
patch("pages.js", 'import { cameraKey, cameraUrl } from "./media.js";\n',
      'import { cameraKey, cameraUrl } from "./media.js";\n' + helper, "camera link helper", done_marker="const pubUrl")
