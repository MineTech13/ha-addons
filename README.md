# MineTech13 Home Assistant Apps

[![Open your Home Assistant instance and show the add app repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FMineTech13%2Fha-addons)

Or add it manually in Home Assistant (Settings → Apps → App store → ⋮ → Repositories):

```
https://github.com/MineTech13/ha-addons
```

## Apps

| App | What it does | Wraps (upstream) |
| --- | --- | --- |
| [Spoolman (Ingress + Direct API)](spoolman-hybrid/README.md) | Spoolman with HA Ingress for remote use plus a direct API port (OctoEverywhere, Moonraker, ...) | [Donkie/Spoolman](https://github.com/Donkie/Spoolman) |
| [ACE Lane Bridge](ace-lane-bridge/README.md) (experimental) | Books filament usage per ACE slot into Spoolman via Moonraker (experimental) | [xNoVoSx/kobra-spoolman](https://github.com/xNoVoSx/kobra-spoolman) |
| [Kobra Vision](kobra-vision/README.md) (experimental) | AI print-failure detection (spaghetti) for the ACE Lane Bridge, Obico's model on the CPU | [xNoVoSx/kobra-spoolman](https://github.com/xNoVoSx/kobra-spoolman) (`vision/`) |

All apps are thin wrappers around the upstream container images, pulled straight from the upstream projects' own registries (Kobra Vision is built from the upstream release tag, because upstream only publishes it as `latest`). This repository is not affiliated with the upstream projects.

## Automatic upstream updates

`.github/workflows/upstream-update.yml` runs daily. For every app listed in [`scripts/upstreams.tsv`](scripts/upstreams.tsv) it:

1. looks up the latest upstream release and checks that the container image for it is published,
2. bumps `ARG UPSTREAM_VERSION` in the `Dockerfile`, `version` in `config.yaml` (as `<upstream>-0`) and the `CHANGELOG.md`,
3. builds the app and runs a smoke test (`scripts/smoke-test.sh`) plus the lint checks,
4. always opens a pull request `update/<app>-<version>`,
5. merges that pull request itself when all checks passed and the update level (patch, minor or major, from the version numbers) is allowed by the app's `auto_merge` column (4th column of `upstreams.tsv`):

   | `auto_merge` | merged automatically |
   | --- | --- |
   | `none` | nothing, every update waits for your review |
   | `patch` | `1.2.3 → 1.2.4` |
   | `minor` | patch and `1.2.3 → 1.3.0` |
   | `major` (or `all`) | everything, including `1.2.3 → 2.0.0` |

   Everything else stays open for you to review and merge. If you close an update PR without merging, that version is not offered again; the next release is.

The branch of a merged or closed pull request is deleted automatically (`.github/workflows/delete-branch.yml`). Optional repo secret `UPDATE_TOKEN` (a fine-grained token of the repo owner with Contents and Pull requests read/write on this repo): update PRs are then opened as you, so their checks start normally without needing approval.

Home Assistant offers the update once it is on `main`. To pin an app to a version, remove its line from `upstreams.tsv`.

## Adding a new app

1. Create `<app>/` with `config.yaml`, `Dockerfile`, `run.sh`, `README.md`, `CHANGELOG.md`, `icon.png`, `logo.png`.
2. Upstream-wrapping app: use `ARG UPSTREAM_VERSION=<x>` + `FROM <image>:${UPSTREAM_VERSION}` and add a line to `scripts/upstreams.tsv`. Optionally add a case for it in `scripts/smoke-test.sh`.
3. Linting picks the new folder up automatically.

Our own changes to an app: bump the `-<rev>` suffix of `version` in its `config.yaml` by hand.

## License

Apache-2.0, see [LICENSE](LICENSE). Upstream projects keep their own licenses (Spoolman: MIT, kobra-spoolman: MIT, its kobra-vision service: AGPL-3.0).
