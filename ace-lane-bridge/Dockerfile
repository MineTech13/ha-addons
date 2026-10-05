ARG UPSTREAM_VERSION=2.21.1
FROM ghcr.io/xnovosx/ace-lane-bridge:${UPSTREAM_VERSION}

# Re-declare: ARGs set before FROM are not visible after it
ARG UPSTREAM_VERSION

# The upstream image runs as an unprivileged user; /data is root-owned in HA
USER root

# Upstream's Spoolman setup script (extra fields + template filaments), pinned to the same tag
ADD https://raw.githubusercontent.com/xNoVoSx/kobra-spoolman/v${UPSTREAM_VERSION}/spoolman/spoolman_setup.py /opt/spoolman_setup.py

COPY run.sh patch-ui.py /
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
