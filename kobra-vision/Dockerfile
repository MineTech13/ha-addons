ARG UPSTREAM_VERSION=4.5.0
# Same Python base as upstream's vision/Dockerfile (upstream pulls it via the AWS ECR mirror for its CI)
FROM python:3.12-slim

# Re-declare: ARGs set before FROM are not visible after it
ARG UPSTREAM_VERSION

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MODEL_PATH=/models/obico-failure.onnx \
    HTTP_PORT=7917

# Upstream only publishes kobra-vision as :latest/:edge, so build it from the release tag instead.
# fetch_model.py downloads Obico's ONNX model and checks its SHA-256.
ADD https://github.com/xNoVoSx/kobra-spoolman/archive/refs/tags/v${UPSTREAM_VERSION}.tar.gz /tmp/upstream.tar.gz
WORKDIR /app
RUN tar -xzf /tmp/upstream.tar.gz -C /tmp \
 && cp -a "/tmp/kobra-spoolman-${UPSTREAM_VERSION}/vision/requirements.txt" \
          "/tmp/kobra-spoolman-${UPSTREAM_VERSION}/vision/fetch_model.py" \
          "/tmp/kobra-spoolman-${UPSTREAM_VERSION}/vision/kobravision" \
          "/tmp/kobra-spoolman-${UPSTREAM_VERSION}/vision/LICENSE" /app/ \
 && rm -rf /tmp/upstream.tar.gz "/tmp/kobra-spoolman-${UPSTREAM_VERSION}" \
 && pip install --no-cache-dir -r /app/requirements.txt \
 && python /app/fetch_model.py /models/obico-failure.onnx

COPY run.sh /
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
