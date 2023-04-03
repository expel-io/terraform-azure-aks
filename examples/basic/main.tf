variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "aks_clusters" {
  type = list
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  features {}
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
}

module "expel_azure_aks_integration" {
  source = "../../"

  # Tenant ID that will be onboarded
  tenant_id = var.tenant_id
  # Subscription ID that will be onboarded
  subscription_id = var.subscription_id
  # Name of Azure AD app to create
  azure_ad_app_name = "Expel AKS Integration - Terraform"
  # Name of Custom Role to create
  azure_custom_role_name = "Expel AKS Role - Terraform"
  # Resource group where storage account will be created
  resource_group_name = var.resource_group_name
  # Resource group location
  resource_group_location = var.resource_group_location
  # Storage account that will hold AKS logs
  storage_account_name = var.storage_account_name
  # AKS clusters to configure diagnostic logs for
  aks_clusters = var.aks_clusters
  # Number of days to retain AKS logs in storage account
  retention_days = 7
}

output "expel_azure_aks_integration" {
  value     = module.expel_azure_aks_integration
  sensitive = true
}
