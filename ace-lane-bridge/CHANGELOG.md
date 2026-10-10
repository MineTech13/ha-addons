# Changelog

## 2.5.0-0
- Initial experimental add-on wrapping ace-lane-bridge 2.5.0.

## 2.5.0-1
- Fix ingress UI: patch the 2.5.0 inline index.html (API calls were hitting the HA root instead of the ingress path).

## 2.5.0-3
- Removed the EMPTY_DEBOUNCE_S option again (not needed; turn off AUTO_UNASSIGN_ON_EMPTY instead).

## 2.5.0-4
- AUTO_UNASSIGN_ON_EMPTY now defaults to false (spools were unassigned whenever the printer went offline).

## 2.8.1-0
- Upgrade to upstream 2.8.1: redesigned web UI (2.6), print view with camera, ACE settings, dryer schedule, purge model.
- Direct access on host port 7913 (web UI, Android app, OrcaSlicer plugin), next to ingress. Clear the host port to disable.
- Devices pair per browser/app: the first pairing code is printed in the add-on log.

## 2.8.1-1
- Fix start error ("bash\r: No such file"): run.sh had CRLF line endings. Added .gitattributes to force LF.

## 2.8.1-2
- New option `RUN_SPOOLMAN_SETUP`: runs upstream's Spoolman setup script (extra fields and template filaments) on start. It only adds, never changes or deletes, and is safe to run repeatedly. Turn it off again after the first run.

## 2.8.1-3
- Flag the add-on as `stage: experimental` so Home Assistant shows the experimental badge.

## 2.8.1-4
- State now lives in the add-on config folder (`/addon_configs/<slug>/`, browsable via Samba/File editor) instead of the hidden `/data`. Existing state in `/data` is copied over once on first start.

## 2.21.0-0
- Upstream update to 2.21.0 ([release notes](https://github.com/xNoVoSx/kobra-spoolman/releases/tag/v2.21.0)).

## 2.21.0-1
- Use `addon_config` map name (accepted by old and new Home Assistant); drop options that only restate defaults.

## 2.21.1-0
- Upstream update to 2.21.1 ([release notes](https://github.com/xNoVoSx/kobra-spoolman/releases/tag/v2.21.1)).

## 2.21.1-1
- Camera under ingress: load single snapshots one after the other instead of the endless MJPEG stream, which did not arrive through the ingress/proxy chain (image stayed empty). Option `INGRESS_CAMERA_SNAPSHOTS` (default on); direct port 7913 still streams MJPEG.
- Copyable camera links on the settings page no longer contain the ingress path (needs a HA login); they use `http://<host>:7913` or the new option `BRIDGE_PUBLIC_URL`.

## 2.21.1-2
- Removed the options `BOOK_USAGE`, `AUTO_UNASSIGN_ON_EMPTY` and `SET_ACE_SLOT_INFO`: upstream moved them into the web UI (Settings), where a saved value overrides the environment, so the add-on options had no effect after the first change there. Existing UI settings are kept; set these in the web UI from now on.

## 2.21.1-3
- Use the `app_config` map name (the `addon_config` name is deprecated in current Home Assistant). Requires a recent Home Assistant; state location (`/addon_configs/<slug>/`) is unchanged.

## 3.6.0-0
- Upstream update to 3.6.0 ([release notes](https://github.com/xNoVoSx/kobra-spoolman/releases/tag/v3.6.0)).

## 2.21.1-4
- Back to upstream 2.21.1. Upstream 3.0.0 and later are for a different setup (Klipper with the ACEPRO driver on a Raspberry Pi) and read the ACE from ACEPRO instead of Rinkhals/GoKlipper's `mmu` object, so on stock firmware + Rinkhals the ACE unit is no longer seen. Upstream: "Stay on 2.21.1 for the stock firmware." Automatic updates now stay on the 2.x line.
