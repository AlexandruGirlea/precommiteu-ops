# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-04

Pull request scans now run on a serverless NVIDIA T4 GPU in your own Azure
subscription. Our five-file test pull request took about 10.5 minutes from
push to result. For 100 PRs averaging 1,000 changed lines across 10 files,
budget about $52–60 a month at Sweden Central list prices, extrapolating
12–15 minutes per PR and including CPU, RAM, GPU and the model share.
See the README for assumptions and exclusions. Your code still never goes
to an LLM provider.

### Changed

- Runners now run on Azure Container Apps serverless NVIDIA T4 GPUs
  (`Consumption-GPU-NC8as-T4`: 8 vCPU, 56 GiB RAM, 16 GB GPU) instead of a
  dedicated CPU profile. On a CPU-only runner, four of the five `risky_code`
  fixture files timed out; on a T4 all five scan in about 4 minutes.
- The runner image is built on llama.cpp's CUDA 12.8 server image and installs
  scanner 0.3.2 from PyPI. It keeps the orchestrator's expert weights in RAM
  and gives the model servers 15 minutes to start.
- The model download job runs on the same GPU profile.
- Terraform creates the Container Apps environment with the `azapi` provider,
  because `azurerm` can't create serverless GPU profiles.
- Ships scanner 0.3.2: runner image
  `ghcr.io/alexandrugirlea/precommiteu-runner:0.2.0` and models revision
  `v0.3.0`.
- Scanner 0.3.2 refreshes documentation and metadata; scanner logic, prompts
  and model weights match the 0.3.1 build used in the Azure test above.

### Removed

- The `workload_profile_type`, `cpu` and `memory` inputs.

## [0.1.0] - 2026-11-03

### Added

- Initial release: a Terraform module and a Pulumi component that run the
  precommitEU scanner on pull requests with a self-hosted GitHub Actions runner
  on Azure Container Apps.
- Ships scanner 0.3.1: runner image
  `ghcr.io/alexandrugirlea/precommiteu-runner:0.1.0` and models revision
  `v0.3.0`.

[0.2.0]: https://github.com/AlexandruGirlea/precommiteu-ops/releases/tag/v0.2.0
[0.1.0]: https://github.com/AlexandruGirlea/precommiteu-ops/releases/tag/v0.1.0
