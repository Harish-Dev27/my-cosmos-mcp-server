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
