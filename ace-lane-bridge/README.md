# ACE Lane Bridge (Spoolman) - EXPERIMENTAL

Wraps the community project [xNoVoSx/kobra-spoolman](https://github.com/xNoVoSx/kobra-spoolman) (`ace-lane-bridge` 3.12.0, MIT) as a Home Assistant add-on. It sits between **Moonraker** and **Spoolman**:

- Assign Spoolman spools to the ACE slots on a web page in the HA sidebar ("ACE Lanes")
- Measures filament use per slot and books it to the right spool in Spoolman
- Writes `lane_data` to Moonraker for Mainsail/Fluidd/OrcaSlicer

> **Both setups:** since upstream 3.12.0 one bridge works with the stock firmware + [Rinkhals](https://github.com/rinkhals-community/Rinkhals) and with Klipper + ACEPRO on a Raspberry Pi. It detects which one from Moonraker; there is nothing to configure.
>
> **Upgrading from 2.21.1 (Rinkhals):** make a backup of the add-on first. Upstream tested the 2.21.1 → 3.12 path with replays and a simulated printer, not yet on a real Rinkhals printer. Settings, paired devices and history carry over.

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

Upstream ships `spoolman_setup.py`, which adds the extra fields (OrcaSlicer settings, NFC tag, drying info) and a "Template" vendor with material template filaments (German names with `UI_LANGUAGE: de`; an existing "Vorlage" vendor from before 3.12 is kept) to Spoolman. It is not needed for slot assignment and booking.

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
| `VISION_URL` | AI print-failure detection: address of the [Kobra Vision](../kobra-vision/README.md) add-on, e.g. `http://<hostname>:7917` (hostname from that add-on's Info page). Empty = AI off. Everything else about the AI is set in the bridge's web UI (AI tab) |
| `VISION_TOKEN` | Only if `VISION_TOKEN` is also set in the Kobra Vision add-on |
| `RUN_SPOOLMAN_SETUP` | Run upstream's Spoolman setup script on start (see below) |
| `SPOOLMAN_PUBLIC_URL`, `PRINTER_UI_URL` | Links shown on the web page |
| `UI_LANGUAGE` | `en` (default) or `de`: language of the printer display, notifications and new devices, and of the names the Spoolman setup script creates. Each browser and the app can still pick their own language |
| `LOG_LEVEL` | `DEBUG` for more detail |

### Optional options

These are hidden under "Show unused optional configuration options". Empty = upstream default. They have no setting in the bridge's web UI; change them here and restart the add-on.

| Option | Meaning |
| --- | --- |
| `MQTT_HOST` | Home Assistant over MQTT: broker address, e.g. `core-mosquitto` for the Mosquitto add-on. Empty = MQTT off |
| `MQTT_PORT`, `MQTT_USER`, `MQTT_PASSWORD` | Broker port (default `1883`) and login |
| `MQTT_PREFIX` | Topic prefix of the bridge (default `kobra-spoolman`) |
| `MQTT_DISCOVERY` | Home Assistant discovery prefix (default `homeassistant`) |
| `ROOM_SENSOR_TOPIC` | MQTT topic of a humidity sensor in the filament storage room, e.g. `zigbee2mqtt/filament_storage` |
| `CAMERA_SNAPSHOT_URL`, `CAMERA_STREAM_URL` | Camera addresses. Empty = taken from Moonraker's webcam list |
| `CAMERA_INTERVAL_S` | A single snapshot request reuses an image younger than this (default `1`) |
| `SPOOLMAN_POLL_S` | How often Spoolman is re-read, in seconds (default `20`) |
| `SLOT_LOCATION_PREFIX` | Spoolman location of a loaded spool (default `ACE Slot `, giving `ACE Slot 1` …) |
| `SHELF_LOCATION`, `TEMPLATE_VENDOR` | Spoolman location of unloaded spools and vendor name of the material templates. Empty = `Shelf`/`Template`, or the German `Regal`/`Vorlage` if your Spoolman already uses them. Changing these on an existing install does not rename anything in Spoolman |
| `LANE_NAMESPACE` | Moonraker database namespace for `lane_data` (default `lane_data`) |
| `EMPTY_GATE_MODE` | `delete` (default) removes empty slots from `lane_data`, `keep` keeps them |
| `GATE_DEBOUNCE_S` | An RFID tag must stay in the slot this long before its spool is assigned; on Rinkhals also how long the active slot must stay the same before usage moves to it (default `3`) |
| `USAGE_TOLERANCE` | Hint when a slot used less than the G-code estimate minus this share (default `0.03` = 3 %) |
| `DEFAULT_DIAMETER`, `DEFAULT_DENSITY` | Only for estimates without a spool (default `1.75` / `1.24`) |
| `TAG_SKU_PREFIX`, `TAG_NR_MIN`, `TAG_NR_MAX` | Numbering of self-written NFC tags, SKU `<prefix>-<number>` (default `AHPEBK` / `1000` / `99999`) |

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
