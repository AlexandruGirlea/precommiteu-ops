FROM ghcr.io/alexandrugirlea/precommiteu:0.3.1

LABEL org.opencontainers.image.source=https://github.com/AlexandruGirlea/precommiteu-ops

ARG RUNNER_VERSION=2.338.2
ARG RUNNER_SHA256=baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40

WORKDIR /opt/actions-runner

RUN curl -fsSLo runner.tar.gz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && echo "${RUNNER_SHA256}  runner.tar.gz" | sha256sum -c - \
    && tar -xzf runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m runner \
    && chown -R runner: /opt/actions-runner

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
