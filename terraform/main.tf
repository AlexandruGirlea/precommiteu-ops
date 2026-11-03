terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

locals {
  ops_version     = "0.1.0"
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

variable "workload_profile_type" {
  type    = string
  default = "E8"
}

variable "cpu" {
  type    = number
  default = 6
}

variable "memory" {
  type    = string
  default = "32Gi"
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

resource "azurerm_container_app_environment" "this" {
  name                = "precommiteu"
  resource_group_name = var.resource_group_name
  location            = var.location

  workload_profile {
    name                  = "precommiteu"
    workload_profile_type = var.workload_profile_type
    minimum_count         = 0
    maximum_count         = length(var.github_repos)
  }
}

resource "azurerm_container_app_environment_storage" "models" {
  for_each                     = toset(["ReadOnly", "ReadWrite"])
  name                         = "models-${lower(each.key)}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = azurerm_storage_account.models.name
  share_name                   = azurerm_storage_share.models.name
  access_key                   = azurerm_storage_account.models.primary_access_key
  access_mode                  = each.key
}

resource "azurerm_container_app_job" "download" {
  name                         = "precommiteu-models"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "precommiteu"
  replica_timeout_in_seconds   = 3600

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name   = "download"
      image  = "ghcr.io/alexandrugirlea/precommiteu:${local.scanner_version}"
      cpu    = 2
      memory = "4Gi"
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
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "precommiteu"
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
      cpu    = var.cpu
      memory = var.memory

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
