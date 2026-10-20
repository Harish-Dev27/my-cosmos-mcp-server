output "container_app_url" {
  description = "Public URL of the Azure Container App."
  value       = "https://${azurerm_container_app.project.latest_revision_fqdn}"
}

output "github_actions_azure_client_id" {
  description = "Client ID to configure as the AZURE_CLIENT_ID GitHub Actions variable."
  value       = azurerm_user_assigned_identity.github_actions.client_id
}

output "github_actions_identity_principal_id" {
  description = "Principal ID of the GitHub Actions managed identity."
  value       = azurerm_user_assigned_identity.github_actions.principal_id
}