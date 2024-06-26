/**
 * Outputs
 *
 * This file defines the outputs for the Terraform module that creates an Azure AKS cluster.
 * These outputs provide information about the resources created for Expel.
 */


# application_client_id
output "application_client_id" {
  description = "Client ID of the Azure Application created for Expel"
  value       = azuread_application.expel_azure_ad_app.application_id
}

# tenant_id
output "tenant_id" {
  description = "The ID of the Azure tenant where resources were created for Expel"
  value       = var.tenant_id
}

# subscription_id
output "subscription_id" {
  description = "The ID of the Azure subscription where resources were created for Expel"
  value       = var.subscription_id
}

# storage_account_name
output "storage_account_name" {
  description = "The name of the Storage Account where AKS logs will be sent"
  value       = var.storage_account_name
}

# application_secret
output "application_secret" {
  description = "The application secret that allows Expel to authenticate"
  value       = azuread_application_password.expel_app_creds.value
  sensitive   = true
}