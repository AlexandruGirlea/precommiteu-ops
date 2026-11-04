FROM ghcr.io/ggml-org/llama.cpp:server-cuda12@sha256:d5ffba7d096ab0236c65dc147d797b4b7658a7e5425634593373635d661bccda

LABEL org.opencontainers.image.source=https://github.com/AlexandruGirlea/precommiteu-ops

ARG SCANNER_VERSION=0.3.2
ARG RUNNER_VERSION=2.338.2
ARG RUNNER_SHA256=baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40

COPY --from=ghcr.io/astral-sh/uv:0.10.10 /uv /usr/local/bin/uv

ENV UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_TOOL_DIR=/opt/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    PATH=/app:$PATH \
    LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64 \
    LLAMA_ARG_CPU_MOE=1 \
    PRECOMMITEU_MODELS_DIR=/models

WORKDIR /opt/actions-runner

# The scanner gives each model server 90 s to start; loading the models from
# Azure Files takes longer, so allow 15 minutes.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git jq \
    && uv tool install --python 3.13 "precommiteu==${SCANNER_VERSION}" \
    && config=/opt/tools/precommiteu/lib/python3.13/site-packages/precommiteu/config.py \
    && sed -i 's/^SERVER_HEALTH_TIMEOUT_S = 90.0$/SERVER_HEALTH_TIMEOUT_S = 900.0/' "$config" \
    && grep -qx 'SERVER_HEALTH_TIMEOUT_S = 900.0' "$config" \
    && curl -fsSLo runner.tar.gz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && echo "${RUNNER_SHA256}  runner.tar.gz" | sha256sum -c - \
    && tar -xzf runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -o -u 10000 runner \
    && chown -R runner: /opt/actions-runner

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER runner

HEALTHCHECK NONE
ENTRYPOINT ["/entrypoint.sh"]
