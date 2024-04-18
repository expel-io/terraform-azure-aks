/*
  This Terraform configuration file sets the required providers and versions for the Azure AD and Azure Resource Manager (AzureRM) providers.

  - The `azuread` provider is sourced from `hashicorp/azuread` with a version constraint of "~> 2.33.0".
  - The `azurerm` provider is sourced from `hashicorp/azurerm` with a version constraint of "~> 3.40.0".

  The `required_version` attribute specifies the minimum Terraform version required to run this configuration, which is ">= 1.1.0".
*/
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.33.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.40.0"
    }
  }
  required_version = ">= 1.1.0"
}
