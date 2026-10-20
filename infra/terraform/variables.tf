variable "azure_subscription_id" {
  description = "Azure subscription ID used by the AzureRM provider."
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID used by the AzureRM provider."
  type        = string
}

variable "project_resource_group_name" {
  description = "Name of the shared resource group for project resources."
  type        = string
}

variable "base_location" {
  description = "Azure region for project resources."
  type        = string
}

variable "container_app_environment_name" {
  description = "Name of the Azure Container Apps environment."
  type        = string
  default     = "cae-cosmos-mcp"
}

variable "container_app_name" {
  description = "Name of the Azure Container App."
  type        = string
  default     = "ca-cosmos-mcp"
}

variable "container_app_env_location" {
  description = "Location of the Azure Container Apps environment."
  type        = string
  default     = "southindia"
}

variable "tags" {
  description = "Tags applied to project resources."
  type        = map(string)
  default     = {}
}
