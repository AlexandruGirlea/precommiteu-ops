terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

locals {
  ops_version     = "0.2.0"
  scanner_version = "0.3.1"
  models_revision = "v0.3.0"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repos" {
  type = list(string)
}

variable "github_pat" {
  type      = string
  sensitive = true
}

variable "regulations" {
  type    = list(string)
  default = ["gdpr"]
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "models" {
  name                     = "precommiteu${substr(sha1(data.azurerm_resource_group.this.id), 0, 13)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "models" {
  name               = "models"
  storage_account_id = azurerm_storage_account.models.id
  quota              = 100
}

# azurerm sends node counts for every workload profile, which serverless GPU
# profiles reject.
resource "azapi_resource" "environment" {
  type      = "Microsoft.App/managedEnvironments@2025-07-01"
  name      = "precommiteu"
  parent_id = data.azurerm_resource_group.this.id
  location  = var.location

  body = {
    properties = {
      workloadProfiles = [
        { name = "Consumption", workloadProfileType = "Consumption" },
        { name = "gpu", workloadProfileType = "Consumption-GPU-NC8as-T4" },
      ]
    }
  }
}

resource "azurerm_container_app_environment_storage" "models" {
  for_each                     = toset(["ReadOnly", "ReadWrite"])
  name                         = "models-${lower(each.key)}"
  container_app_environment_id = azapi_resource.environment.id
  account_name                 = azurerm_storage_account.models.name
  share_name                   = azurerm_storage_share.models.name
  access_key                   = azurerm_storage_account.models.primary_access_key
  access_mode                  = each.key
}

resource "azurerm_container_app_job" "download" {
  name                         = "precommiteu-models"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  container_app_environment_id = azapi_resource.environment.id
  workload_profile_name        = "gpu"
  replica_timeout_in_seconds   = 3600

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name   = "download"
      image  = "ghcr.io/alexandrugirlea/precommiteu:${local.scanner_version}"
      cpu    = 8
      memory = "56Gi"
      command = concat(
        ["hf", "download", "AlexandruGirlea/precommiteu-models", "base.gguf", "orchestrator.gguf"],
        [for r in var.regulations : "${r}/detector-adapter.gguf"],
        ["--revision", local.models_revision, "--local-dir", "/models"],
      )

      volume_mounts {
        name = "models"
        path = "/models"
      }
    }

    volume {
      name         = "models"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.models["ReadWrite"].name
    }
  }
}

resource "azurerm_container_app_job" "runner" {
  for_each                     = toset(var.github_repos)
  name                         = trimsuffix(substr(replace(lower("runner-${each.key}"), "/[^a-z0-9]+/", "-"), 0, 32), "-")
  resource_group_name          = var.resource_group_name
  location                     = var.location
  container_app_environment_id = azapi_resource.environment.id
  workload_profile_name        = "gpu"
  replica_timeout_in_seconds   = 7200

  secret {
    name  = "github-pat"
    value = var.github_pat
  }

  event_trigger_config {
    parallelism              = 1
    replica_completion_count = 1

    scale {
      min_executions = 0
      max_executions = 1

      rules {
        name             = "github-runner"
        custom_rule_type = "github-runner"
        metadata = {
          owner       = var.github_owner
          runnerScope = "repo"
          repos       = each.key
          labels      = "precommiteu"
        }

        authentication {
          secret_name       = "github-pat"
          trigger_parameter = "personalAccessToken"
        }
      }
    }
  }

  template {
    container {
      name   = "runner"
      image  = "ghcr.io/alexandrugirlea/precommiteu-runner:${local.ops_version}"
      cpu    = 8
      memory = "56Gi"

      env {
        name        = "GITHUB_PAT"
        secret_name = "github-pat"
      }

      env {
        name  = "GITHUB_REPO"
        value = "${var.github_owner}/${each.key}"
      }

      volume_mounts {
        name = "models"
        path = "/models"
      }
    }

    volume {
      name         = "models"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.models["ReadOnly"].name
    }
  }
}

output "download_job_name" {
  value = azurerm_container_app_job.download.name
}
