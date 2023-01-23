variable "tenant_id" {
  description = "The Azure Tenant ID that will be onboarded with Expel Workbench."
  type        = string
}

variable "subscription_id" {
  description = "The Azure Subscription ID that will be onboarded with Expel Workbench."
  type        = string
}

variable "azure_custom_role_name" {
  description = "The name of the Azure custom IAM role to be created."
  type        = string
  default     = "Expel AKS Role"
}

variable "azure_ad_app_name" {
  description = "The name of the Azure AD app to be created."
  type        = string
  default     = "Expel AKS Integration"
}
