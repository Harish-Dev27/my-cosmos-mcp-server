terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
  }
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id

  features {}
}

# Common resource group to hold all resources for this project
resource "azurerm_resource_group" "project_rg" {
  name     = var.project_resource_group_name
  location = var.base_location

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "id-cosmos-mcp-github"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name

  tags = var.tags
}

resource "azurerm_federated_identity_credential" "github_actions" {
  name                = "github-main"
  resource_group_name = azurerm_resource_group.project_rg.name
  parent_id           = azurerm_user_assigned_identity.github_actions.id
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:Harish-Dev27@139973876/my-cosmos-mcp-server@1390945630:ref:refs/heads/main"
  audience            = ["api://AzureADTokenExchange"]
}

resource "azurerm_container_app_environment" "project" {
  name                = var.container_app_environment_name
  location            = var.container_app_env_location
  resource_group_name = azurerm_resource_group.project_rg.name

  tags = var.tags
}

resource "azurerm_container_app" "project" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.project.id
  resource_group_name          = azurerm_resource_group.project_rg.name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "hello-world"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    cors {
      allowed_headers = ["*"]
      allowed_origins = ["*"]
    }

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}

resource "azurerm_role_assignment" "github_actions_container_app" {
  scope                = azurerm_container_app.project.id
  role_definition_name = "Container Apps Contributor"
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
  principal_type       = "ServicePrincipal"
}
