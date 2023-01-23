variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
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

}

output "expel_azure_aks_integration" {
  value     = module.expel_azure_aks_integration
  sensitive = true
}
