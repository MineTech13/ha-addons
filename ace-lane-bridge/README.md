# ACE Lane Bridge (Spoolman) - EXPERIMENTAL

Wraps the community project [xNoVoSx/kobra-spoolman](https://github.com/xNoVoSx/kobra-spoolman) (`ace-lane-bridge` 2.8.1, MIT) as a Home Assistant add-on. It sits between **Moonraker** (Rinkhals) and **Spoolman**:

- Assign Spoolman spools to the ACE slots on a web page in the HA sidebar ("ACE Lanes")
- Measures filament use per slot and books it to the right spool in Spoolman
- Writes `lane_data` to Moonraker for Mainsail/Fluidd/OrcaSlicer

> **Version line:** this add-on stays on upstream **2.x** (stock firmware + Rinkhals). Upstream 3.x needs Klipper with the ACEPRO driver on a Raspberry Pi and does not see the ACE on Rinkhals, so automatic updates are limited to 2.x.

> The upstream project targets the **Kobra S1 + ACE 2 Pro**. A **Kobra 3 + ACE Pro** is untested. Start with `DRY_RUN: true`, which logs what would be booked and writes nothing, and compare with a real print before turning it off.

## Setup

1. Install the **Spoolman (Ingress + Direct API)** add-on (mode `both`, the default; `ingress` mode closes the direct port the bridge needs).
2. Set the options here:
   - `MOONRAKER_URL`: `http://<printer-ip>:7125`
   - `SPOOLMAN_URL`: `http://<HA-IP>:7912`
3. Start the add-on and open **ACE Lanes** in the sidebar.
4. Assign a spool to each ACE slot.
5. Do a test print with `DRY_RUN: true` and read the add-on log. When the numbers look right, set `DRY_RUN: false`.

Do not also enable Moonraker's own `[spoolman]` booking for the same prints, or usage is counted twice.

## Spoolman setup script (optional)

Upstream ships `spoolman_setup.py`, which adds the extra fields (OrcaSlicer settings, NFC tag, drying info) and a "Vorlage" vendor with material template filaments to Spoolman. It is not needed for slot assignment and booking.

The script is bundled in this add-on (same version as the bridge). To run it: set `RUN_SPOOLMAN_SETUP` to `true` and restart the add-on. It waits for Spoolman, runs once, and the result is in the add-on log. It only adds missing things, never changes or deletes existing ones, so running it repeatedly is harmless; set the option back to `false` afterwards to skip the wait on later starts. Home Assistant add-ons cannot have custom buttons, so this option is the way to trigger it.

## Options

| Option | Meaning |
| --- | --- |
| `MOONRAKER_URL` | Moonraker on the printer |
| `SPOOLMAN_URL` | Spoolman API, e.g. the direct port of the Spoolman add-on |
| `MOONRAKER_API_KEY` | Only if Moonraker requires one |
| `DRY_RUN` | Log only, write nothing |
| `INGRESS_CAMERA_SNAPSHOTS` | Default on. Under ingress the camera is loaded as single snapshots (a few fps) instead of the MJPEG stream, which does not arrive reliably through the HA ingress / reverse proxy chain. Turn off to try the stream. The direct port 7913 always streams MJPEG |
| `BRIDGE_PUBLIC_URL` | Base address used in the copyable camera links on the settings page (e.g. `http://192.168.1.10:7913`). Default under ingress: `http://<hostname you opened HA with>:7913` |
| `RUN_SPOOLMAN_SETUP` | Run upstream's Spoolman setup script on start (see below) |
| `SPOOLMAN_PUBLIC_URL`, `PRINTER_UI_URL` | Links shown on the web page |
| `LOG_LEVEL` | `DEBUG` for more detail |

Runtime settings (usage booking, auto-unassign on empty, ACE slot info, camera, print preview, moisture, notices and more) are changed in the bridge's web UI under Settings, not here. Upstream only uses the matching environment variables as start values; a value saved in the UI wins from then on.

## Access

- **Ingress**: the web UI in the HA sidebar ("ACE Lanes").
- **Direct**: host port `7913` (`http://<HA-IP>:7913`) for the Android app, the OrcaSlicer plugin and API access. Clear the host port in the add-on's Network section to disable it.

Writes need a paired device. Pairing is per browser/app: on first start the add-on log prints a setup code, enter it in the web UI (ingress and direct are separate browser origins, so pair each once). There is no TLS, keep the port inside your home network.

Full upstream settings: [docs/configuration.md](https://github.com/xNoVoSx/kobra-spoolman/blob/main/docs/configuration.md).

## Storage

All state (paired devices, settings, dryer rules, moisture and print history, journal) is kept in the add-on config folder, visible as `/addon_configs/<slug>/` (Samba, File editor) and included in backups. Versions before 2.8.1-4 used the hidden `/data` folder; its content is copied over once on the first start of the new version (marker file `.migrated-from-data`).

## Camera

- For Mainsail/OrcaSlicer etc. use the links from the bridge's settings page: they point at the direct port (`:7913`) and carry the camera key, so they work without a HA login.
- Camera in the HA sidebar (ingress) uses snapshots, see `INGRESS_CAMERA_SNAPSHOTS`. For a smooth stream open the direct port `http://<HA-IP>:7913` instead.
- Rotate the camera key in the bridge (Settings → Camera) if a link was shared by accident.
