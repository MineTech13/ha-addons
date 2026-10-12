# Spoolman (Ingress + Direct API)

Spoolman for Home Assistant with both access methods:

- **Ingress** (sidebar "Spoolman"): full web UI, works remotely through Home Assistant / Nabu Casa. Only reachable via the HA Supervisor.
- **Direct port 7912**: `http://<HA-IP>:7912/api/v1/...`. Use this for integrations like OctoEverywhere, Moonraker or Klipper that talk to the Spoolman API.

## Options

| Option | Description |
| --- | --- |
| `SPOOLMAN_DEBUG_MODE` | Verbose logging |
| `SPOOLMAN_LEGACY_CLIENT` | Use the legacy web client |
| `SPOOLMAN_CORS_ORIGIN` | Allowed CORS origin (browser-based clients only) |
| `ACCESS_MODE` | `both` (default), `ingress` or `direct` (see below) |
| `DIRECT_API_ONLY` | Only used in `both` mode. `true` (default): direct port serves only `/api/`. `false`: proxy everything (the UI will not render properly there because its links carry the ingress path) |

### Optional options

Hidden under "Show unused optional configuration options". Empty = Spoolman's default. Spoolman has no setting for these in its web UI; restart the add-on after changing them.

| Option | Description |
| --- | --- |
| `SPOOLMAN_LOGGING_LEVEL` | `DEBUG`, `INFO` (default), `WARNING`, `ERROR` or `CRITICAL` |
| `SPOOLMAN_AUTOMATIC_BACKUP` | Nightly database backup into `backups/` (default on) |
| `SPOOLMAN_METRICS_ENABLED` | Adds spool and filament values to the Prometheus metrics at `http://<HA-IP>:7912/metrics` (default off) |
| `SPOOLMAN_ALLOWED_HOSTS` | Comma-separated hostnames Spoolman answers to, e.g. `spoolman.example.com`. Only needed if you reach the direct port through a public domain name; IP addresses and local names always work |
| `SPOOLMAN_DB_TYPE` | `sqlite` (default, stored in the add-on config folder), `mysql`, `postgres` or `cockroachdb`. For the MariaDB add-on use `mysql` with host `core-mariadb`. Switching does not move existing data |
| `SPOOLMAN_DB_HOST`, `SPOOLMAN_DB_PORT`, `SPOOLMAN_DB_NAME` | External database server, port and database name |
| `SPOOLMAN_DB_USERNAME`, `SPOOLMAN_DB_PASSWORD` | External database login |
| `SPOOLMAN_DB_QUERY` | Extra connection parameters as a query string, e.g. `unix_socket=/path/to/socket` |
| `EXTERNAL_DB_URL` | Filament catalog to import from (default SpoolmanDB) |
| `EXTERNAL_DB_NAME` | Display name of that catalog in the UI |
| `EXTERNAL_DB_SYNC_INTERVAL` | Seconds between catalog syncs (default `3600`, `0` = off) |

## Access modes

| Mode | Ingress (sidebar) | Direct port 7912 |
| --- | --- | --- |
| `both` | Full web UI | API only (or full proxy, see `DIRECT_API_ONLY`) |
| `ingress` | Full web UI | Disabled |
| `direct` | Shows a notice | Full web UI and API (Spoolman runs at the root path) |

Restart the add-on after changing the mode.

**Use `both` (default).** It is the only mode that is tested and supported. Other add-ons such as ACE Lane Bridge reach Spoolman through the direct port 7912, so `ingress` (port disabled) will most likely break them. `direct` is untested as a daily driver.

## OctoEverywhere / Moonraker

Set the Spoolman server to `http://<HA-IP>:7912` (no trailing path).

Do not run this alongside the `spoolman` or `spoolman-ingress` add-ons without changing ports: they share `/config` data and the `spoolman` add-on also uses port 7912.

Note: the direct port has no authentication, same as stock Spoolman. Keep it on your LAN.
