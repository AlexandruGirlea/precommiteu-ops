# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-03

### Added

- Initial release: a Terraform module and a Pulumi component that run the
  precommitEU scanner on pull requests with a self-hosted GitHub Actions runner
  on Azure Container Apps.
- Ships scanner 0.3.1: runner image
  `ghcr.io/alexandrugirlea/precommiteu-runner:0.1.0` and models revision
  `v0.3.0`.

[0.1.0]: https://github.com/AlexandruGirlea/precommiteu-ops/releases/tag/v0.1.0
