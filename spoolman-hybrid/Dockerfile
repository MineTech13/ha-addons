ARG UPSTREAM_VERSION=0.27.0
FROM ghcr.io/donkie/spoolman:${UPSTREAM_VERSION}

USER root
RUN apt-get update && apt-get install -y --no-install-recommends curl nginx && rm -rf /var/lib/apt/lists/*

# 8099 = HA ingress, 7912 = direct access
EXPOSE 8099 7912

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
