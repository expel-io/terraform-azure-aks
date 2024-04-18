# Terraform Module for Azure Kubernetes Service (AKS)

This Terraform module configures Azure Kubernetes Service (AKS) to integrate with [Expel Workbench](https://workbench.expel.io/). It sets up an Azure AD application registration and a custom role that Expel Workbench uses for onboarding.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
- [Example](#example)
- [Permissions](#permissions)
- [Limitations](#limitations)
- [Issues](#issues)
- [Contributing](#contributing)
- [Requirements](#requirements)
- [Providers](#providers)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Resources](#resources)

## Features

- Creates an Azure AD application registration for Expel Workbench
- Creates a custom role for Expel Workbench
- Configures diagnostic logs for AKS clusters
- Creates a Storage Account for AKS logs
- Sends AKS logs to the Storage Account
- Retains AKS logs in the Storage Account for a specified number of days

## Usage

```shell
module "expel_azure_aks_integration" {
  source  = "expel-io/aks/azure"

  # Tenant ID that will be onboarded
  tenant_id = "YOUR_TENANT_ID"
  # Subscription ID that will be onboarded
  subscription_id = "YOUR_SUBSCRIPTION_ID"
  # Name of Azure AD app to create
  azure_ad_app_name = "Expel AKS Integration"
  # Name of Custom Role to create
  azure_custom_role_name = "Expel AKS Role"
  # Resource group where storage account will be created
  resource_group_name = "YOUR_RESOURCE_GROUP_NAME"
  # Resource group location
  resource_group_location = "YOUR_LOCATION_NAME"
  # Storage account that will hold AKS logs
  storage_account_name = "YOUR_STORAGE_ACCOUNT_NAME"
  # AKS clusters to configure diagnostic logs for
  aks_clusters = ["/subscriptions/YOUR_SUBSCRIPTION_NAMEresourceGroups/YOUR_RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/YOUR_CLUSTER_NAME"]
  # Number of days to retain AKS logs in storage account
  retention_days = 7

}
```

After configuring your Azure environment, visit [Expel Workbench](https://workbench.expel.io/settings/security-devices?setupIntegration=kubernetes_aks) to create an AKS security device. This enables Expel to start monitoring your AWS environment.

> **Note:** Terraform state may contain sensitive information. Ensure you follow best security practices when securing your state.

## Permissions

This module grants permissions that allow Expel Workbench to perform investigations and discover AKS clusters in the environment.

## Example

- [Basic](/examples/basic/)

## Limitations

1. This module will always create a new Azure Active Directory application registration.
2. It will always create a new Storage Account for logging.

Refer to Expel's Getting Started Guide for AKS for more onboarding information.

## Issues

Found a bug or have an idea for a new feature? Please [create an issue](https://github.com/expel-io/terraform-azure-aks/issues). We'll respond as soon as possible!

## Contributing

We welcome contributions! Here's how you can help:

1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

Please read our [Contributing Code of Conduct](CONTRIBUTING.md) to get started.

<!-- begin-tf-docs -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.33.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.40.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.33.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.40.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | The resource group location where the Storage Account for AKS logs will be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group name where the Storage Account for AKS logs will be created. | `string` | n/a | yes |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The name of the Storage Account to be created for AKS logs. | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The Azure Subscription ID that will be onboarded with Expel Workbench. | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | The Azure Tenant ID that will be onboarded with Expel Workbench. | `string` | n/a | yes |
| <a name="input_aks_clusters"></a> [aks\_clusters](#input\_aks\_clusters) | The list of AKS clusters to configure diagnostic logs for. If configured elsewhere, this can be left empty. | `list(any)` | `[]` | no |
| <a name="input_azure_ad_app_name"></a> [azure\_ad\_app\_name](#input\_azure\_ad\_app\_name) | The name of the Azure AD app to be created. | `string` | `"Expel AKS Integration"` | no |
| <a name="input_azure_custom_role_name"></a> [azure\_custom\_role\_name](#input\_azure\_custom\_role\_name) | The name of the Azure custom IAM role to be created. | `string` | `"Expel AKS Role"` | no |
| <a name="input_retention_days"></a> [retention\_days](#input\_retention\_days) | The number of days to retain AKS logs in storage. | `number` | `7` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_client_id"></a> [application\_client\_id](#output\_application\_client\_id) | Client ID of the Azure Application created for Expel |
| <a name="output_application_secret"></a> [application\_secret](#output\_application\_secret) | The application secret that allows Expel to authenticate |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The name of the Storage Account where AKS logs will be sent |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | The ID of the Azure subscription where resources were created for Expel |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | The ID of the Azure tenant where resources were created for Expel |
## Resources

| Name | Type |
|------|------|
| [azuread_application.expel_azure_ad_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.expel_app_creds](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.expel_svc_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_monitor_diagnostic_setting.aks_diagnostic_logs_to_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_resource_group.aks_logs_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.expel_app_la_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.expel_app_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.expel_app_sa_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.expel_aks_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_storage_account.aks_logs_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
<!-- end-tf-docs -->
