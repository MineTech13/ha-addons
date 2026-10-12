# Changelog

## 0.27.0-0
- Initial combined Ingress + direct API add-on.

## 0.27.0-1
- Use `addon_config` map name (accepted by old and new Home Assistant); drop options that only restate defaults.

## 0.27.0-2
- Use the `app_config` map name (the `addon_config` name is deprecated in current Home Assistant). Requires a recent Home Assistant.

## 0.27.0-3
- New optional options for Spoolman settings that have no place in its web UI: `SPOOLMAN_LOGGING_LEVEL`, `SPOOLMAN_AUTOMATIC_BACKUP`, `SPOOLMAN_METRICS_ENABLED`, `SPOOLMAN_ALLOWED_HOSTS`, an external database (`SPOOLMAN_DB_TYPE`, `SPOOLMAN_DB_HOST`, `SPOOLMAN_DB_PORT`, `SPOOLMAN_DB_NAME`, `SPOOLMAN_DB_USERNAME`, `SPOOLMAN_DB_PASSWORD`, `SPOOLMAN_DB_QUERY`) and the filament catalog (`EXTERNAL_DB_URL`, `EXTERNAL_DB_NAME`, `EXTERNAL_DB_SYNC_INTERVAL`). All empty by default, so nothing changes unless you set them.
