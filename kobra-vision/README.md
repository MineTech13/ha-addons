# Kobra Vision (AI failure detection) - EXPERIMENTAL

Wraps **kobra-vision** from the community project [xNoVoSx/kobra-spoolman](https://github.com/xNoVoSx/kobra-spoolman) (`vision/`, release 3.12.0, **AGPL-3.0**) as a Home Assistant add-on. It is the AI part of the [ACE Lane Bridge](../ace-lane-bridge/README.md):

- While a print runs, the bridge sends it a camera picture every 10 s.
- It runs [Obico](https://github.com/TheSpaghettiDetective/obico-server)'s failure model (the former *Spaghetti Detective*) with ONNX Runtime on the CPU and returns what it found.
- The bridge judges the pictures over time and raises an alarm (web UI, Android app), optionally pausing the print.

The add-on has no web page of its own. Everything is set and inspected in the bridge's web UI, tab **AI**. How the detection works: upstream [docs/vision.md](https://github.com/xNoVoSx/kobra-spoolman/blob/main/docs/vision.md).

> **Load:** about 50 ms per picture with 2 threads on a desktop CPU, so far below 1 % of one core at one picture every 10 s. The model (~190 MB) is loaded on the first picture and unloaded after `UNLOAD_AFTER_S` without pictures, so it uses no memory while nothing prints. The add-on image is roughly 0.5 GB.

## Setup

1. Install and start this add-on. The first install takes a while: Home Assistant builds the image from the upstream release and downloads Obico's model (its checksum is checked).
2. Restart the **ACE Lane Bridge** add-on. With its `VISION_URL` empty it finds this add-on on its own (the bridge log shows `Autodetect: VISION_URL = ...`). Only if that does not work, set `VISION_URL` to `http://<hostname>:7917`, with the **Hostname** from this add-on's **Info** page (something like `xxxxxxxx-kobra-vision`).
3. Open **ACE Lanes** → **AI**. The status should show the service as ready (CPU) after a few seconds.

Start with the default action *notify only*. Switch to *pause* only after a few weeks without false alarms.

## Options

| Option | Meaning |
| --- | --- |
| `THREADS` | CPU threads per picture (default 2) |
| `UNLOAD_AFTER_S` | Unload the model after this many seconds without a picture (default 600) |
| `VISION_TOKEN` | Optional key. If set, every request needs it: set the same value as `VISION_TOKEN` in the ACE Lane Bridge |
| `LOG_LEVEL` | `DEBUG` for more detail |

## Network

The bridge reaches this add-on over Home Assistant's internal network by its hostname; no port is opened by default. Only if the bridge runs somewhere else (not as an add-on), enable host port `7917` in the add-on's Network section and use `http://<HA-IP>:7917`; set a `VISION_TOKEN` then.

## Notes

- CPU only. Upstream's Nvidia GPU variant (`onnxruntime-gpu`) is not offered here.
- The pictures and your feedback (dataset, up to 5 GB) are stored by the bridge, not here. This add-on keeps no state.
- License: kobra-vision is AGPL-3.0 because it runs Obico's model and post-processing; the source is upstream's `vision/` folder at the matching release tag.
