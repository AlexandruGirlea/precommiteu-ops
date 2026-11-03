# precommitEU ops

Run the [precommitEU](https://github.com/AlexandruGirlea/precommiteu) scanner
on pull requests with a self-hosted GitHub Actions runner on Azure Container
Apps, added from your Terraform or Pulumi code. It scales to zero when idle.

## What it creates

In an existing resource group:
- a Container Apps environment with one dedicated workload profile (`E8` by
  default: 8 vCPU, 64 GiB) that scales from zero nodes
- a premium Azure Files share with the models, read-only at `/models` in runners
- `precommiteu-models`, a manual job that downloads the models into the share
- per repository, an event-driven job that starts a one-job runner when a
  workflow job asks for the `precommiteu` label

Idle, no node runs: you pay the Dedicated plan management fee and the share.

## GitHub token

Create a fine-grained personal access token with `github_owner` as the
resource owner and access to only the repositories you scan:

| Repository permission | Access | Used by |
|---|---|---|
| Actions | Read-only | the scaler, to see queued jobs |
| Administration | Read and write | the runner, to register itself |
| Metadata | Read-only | required |

## Terraform

```hcl
module "precommiteu" {
  source              = "git::https://github.com/AlexandruGirlea/precommiteu-ops.git//terraform?ref=v0.1.0"
  resource_group_name = "ci"
  location            = "westeurope"
  github_owner        = "my-org"
  github_repos        = ["api", "web"]
  github_pat          = var.github_pat
}
```

Optional inputs: `regulations` (`["gdpr"]`), `workload_profile_type` (`"E8"`),
`cpu` (`6`), `memory` (`"32Gi"`).

## Pulumi

Works from any Pulumi language, with the same inputs:

```bash
pulumi package add github.com/AlexandruGirlea/precommiteu-ops.git/pulumi@v0.1.0
```

```python
import pulumi
import pulumi_precommiteu as precommiteu

runner = precommiteu.Runner(
    "precommiteu",
    resource_group_name="ci",
    location="westeurope",
    github_owner="my-org",
    github_repos=["api", "web"],
    github_pat=pulumi.Config().require_secret("githubPat"),
)
pulumi.export("download_job_name", runner.download_job_name)
```

## Download the models

Run the `download_job_name` job after the first deploy and each version change:

```bash
az containerapp job start --name precommiteu-models --resource-group ci
```

## Workflow

```yaml
on: pull_request
permissions:
  contents: read
jobs:
  precommiteu:
    runs-on: [self-hosted, precommiteu]
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: AlexandruGirlea/precommiteu@v0.3.1
```

If you changed `regulations`, set the action's `regulations` input to the same
packs, comma-separated.

## Versioning

Each release pins one scanner version: see [CHANGELOG](CHANGELOG.md).

## Updating

Bump the `ref` or the `@` tag to the new release and apply, run the download
job again, and set the action tag in your workflow to its scanner version.

## Security

Use it for private repositories only: on a public repository, pull requests
from forks would run on your runner. The PAT ends up in your Terraform or
Pulumi state, so protect the state.

[Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md) · [Security policy](SECURITY.md)
