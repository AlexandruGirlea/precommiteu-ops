---
title: Operate
nav_order: 5
---

# Operate precommitEU ops

## What it creates

In an existing resource group:

- a Container Apps environment with a serverless GPU workload profile
  (`Consumption-GPU-NC8as-T4`: 8 vCPU, 56 GiB RAM, one 16 GB NVIDIA T4)
- a premium Azure Files share with the models, read-only at `/models` in runners
- `precommiteu-models`, a manual job that downloads the models into the share
- per repository, an event-driven job that starts a one-job runner when a
  workflow job asks for the `precommiteu` label

Idle, nothing runs: you pay only for the share.

Use a region with Container Apps serverless T4 GPUs, such as `swedencentral`,
`francecentral` or `westeurope`. If Azure refuses the GPU profile, request
"Managed Environment Consumption T4 Gpus" quota in a support request.

## Network access

precommitEU brings its own models and runs them on a GPU inside your Azure
subscription. All inference runs locally on the runner, using the downloaded
model bundle. Scanning requires no LLM API key.

The deployment is not network-isolated: runners need GitHub for registration,
job polling, checkout and report uploads, and GHCR for container images.
The model download job also needs Hugging Face and its download endpoints.
Azure manages the resources and storage inside your subscription. No source
code is sent to Hugging Face or an external LLM API. For a disconnected
scanner installation, see the
[offline guide](https://alexandrugirlea.github.io/precommiteu/install.html#air-gapped-and-offline-installation).

## Choose when to upgrade

Each precommitEU ops release pins the scanner, the runner image tag and the
model revision. You control which version runs in your environment and when
to upgrade. These pins identify the software and weights; results can vary
across hardware or runtime changes.

## Versioning

Each release pins one scanner version, one runner image and one model revision:
see [changelog](https://github.com/AlexandruGirlea/precommiteu-ops/blob/main/CHANGELOG.md).

| Component | Ops 0.2.0 uses |
|---|---|
| Terraform / Pulumi | `v0.2.0` |
| GPU runner image | `ghcr.io/alexandrugirlea/precommiteu-runner:0.2.0` |
| Scanner / GitHub Action / model-download image | `0.3.2` |
| Hugging Face bundle | `v0.3.0` |

Scanner 0.3.2 has a 90-second startup limit. This runner image raises it to
15 minutes at build time, which was tested on Azure. No scanner API change
or unreleased chunk-timeout option is required for this deployment.

## Updating

Bump the `ref` or the `@` tag to the new release and apply, run the download
job again, and set the action tag in your workflow to its scanner version.
Drain queued/running scans while updating the shared model files, then wait
for a successful download before resuming. Model tags need not match scanner
tags; use the combination in the release notes.

## Security

Use it for private repositories only: on a public repository, pull requests
from forks would run on your runner. The PAT ends up in your Terraform or
Pulumi state, so protect the state.

[Security policy](https://github.com/AlexandruGirlea/precommiteu-ops/blob/main/SECURITY.md).
