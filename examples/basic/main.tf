# This Terraform configuration file sets up an integration with Expel for Azure AKS clusters.
# It creates an Azure AD app, a custom role, and configures diagnostic logs for the AKS clusters
variable "tenant_id" {
description = "The Azure Tenant ID that will be onboarded with Expel Workbench."
  type = string
    validation {
    condition     = length(var.tenant_id) > 0
    error_message = "The tenant_id must be provided."
  }
}

variable "subscription_id" {
  description = "The Azure Subscription ID that will be onboarded with Expel Workbench."
  type = string
}

variable "resource_group_name" {
  description = "The resource group name where the Storage Account for AKS logs will be created."
  type = string
}

variable "resource_group_location" {
  description = "The resource group location where the Storage Account for AKS logs will be created."
  type = string
}

variable "storage_account_name" {
  description = "The name of the Storage Account to be created for AKS logs."
  type = string
}

variable "aks_clusters" {
  description = "The list of AKS clusters to configure diagnostic logs for. If configured elsewhere, this can be left empty."
  type = list
}

# Set up the Azure AD and Azure Resource Manager providers
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
