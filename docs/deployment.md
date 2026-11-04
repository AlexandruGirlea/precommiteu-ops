---
title: Deploy
nav_order: 2
---

# Deploy precommitEU ops

Use Terraform or Pulumi to create the runner infrastructure. Both deploy
the same scanner and model versions. The deployment below assumes the
resource group is named `ci`.

## Prerequisites

Start with an Azure subscription, an existing resource group in a supported
region, and T4 GPU quota. The deploying identity needs permission to create
the resources and read storage account keys. Register `Microsoft.App`,
`Microsoft.Storage` and `Microsoft.OperationalInsights` if the subscription
has not used Container Apps before. Organization policy must allow
self-hosted runners and the actions below; the PAT may need organization
approval. Quota and policy approval can take longer than deployment.

Install Terraform and Azure CLI, run `az login`, and set
`ARM_SUBSCRIPTION_ID` to the intended subscription. Install the Container Apps
CLI extension with `az extension add --name containerapp --upgrade`.

## GitHub token

Create a fine-grained personal access token with `github_owner` as the
resource owner and access to only the repositories you scan:

| Repository permission | Access | Used by |
|---|---|---|
| Actions | Read-only | the scaler, to see queued jobs |
| Administration | Read and write | the runner, to register itself |
| Metadata | Read-only | required |

## Terraform

In a Terraform project:

```hcl
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 5.0" }
    azapi   = { source = "Azure/azapi", version = "~> 2.0" }
  }
}

provider "azurerm" {
  features {}
}
provider "azapi" {}

variable "github_pat" {
  type      = string
  sensitive = true
}

module "precommiteu" {
  source              = "git::https://github.com/AlexandruGirlea/precommiteu-ops.git//terraform?ref=v0.2.0"
  resource_group_name = "ci"
  location            = "swedencentral"
  github_owner        = "my-org"
  github_repos        = ["api", "web"]
  github_pat          = var.github_pat
}

output "download_job_name" {
  value = module.precommiteu.download_job_name
}
```

Supply `TF_VAR_github_pat` through your secret manager or shell environment;
do not commit it in a tfvars file. Then run:

```bash
terraform init
terraform plan
terraform apply
```

Optional input: `regulations` (`["gdpr"]`). The module uses the `azurerm` and
`azapi` providers: `azurerm` can't create serverless GPU profiles yet.

## Pulumi

Use the [prerequisites](#prerequisites) above. In an Azure Pulumi project, after
`az login`, configure the subscription and PAT (the secret command prompts
for the value):

```bash
pulumi config set azure-native:subscriptionId <subscription-id>
pulumi config set --secret githubPat
pulumi package add github.com/AlexandruGirlea/precommiteu-ops.git/pulumi@v0.2.0
```

```python
import pulumi
import pulumi_precommiteu as precommiteu

runner = precommiteu.Runner(
    "precommiteu",
    resource_group_name="ci",
    location="swedencentral",
    github_owner="my-org",
    github_repos=["api", "web"],
    github_pat=pulumi.Config().require_secret("githubPat"),
)
pulumi.export("download_job_name", runner.download_job_name)
```

Run `pulumi preview`, then `pulumi up`. The component works from other Pulumi
languages through the generated package with the same inputs.

## Download the models

Run the `download_job_name` job after the first deploy and each version change:

```bash
az containerapp job start --name precommiteu-models --resource-group ci
```

Starting the job does not mean the download is finished. Check the newest
execution and wait for `Succeeded` before enabling the workflow:

```bash
az containerapp job execution list --name precommiteu-models --resource-group ci --query '[].{name:name,status:properties.status}' --output table
```

The job downloads both shared models and the selected adapters from
`v0.3.0` (`fe15487df95233aac4478f9a08e2fc12e8dda7f1`). A failed download
must be resolved before scanning. After changing packs, rerun this job and
match the action's `regulations` input to the deployed list.

When the download succeeds, [connect the CI workflow](ci.md).
