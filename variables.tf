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

variable "resource_group_name" {
  description = "The resource group name where the Storage Account for AKS logs will be created."
  type        = string
}

variable "resource_group_location" {
  description = "The resource group location where the Storage Account for AKS logs will be created."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the Storage Account to be created for AKS logs."
  type        = string
}

variable "aks_clusters" {
  description = "The list of AKS clusters to configure diagnostic logs for. If configured elsewhere, this can be left empty."
  type        = list(any)
  default     = []
}

variable "retention_days" {
  description = "The number of days to retain AKS logs in storage."
  type        = number
  default     = 7
}
