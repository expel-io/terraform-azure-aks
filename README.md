# terraform-azure-aks
Terraform module for configuring Azure Kubernetes Service (AKS) to integrate with [Expel Workbench](https://workbench.expel.io/).

Configures an Azure AD application registration and custom role that
[Expel Workbench](https://workbench.expel.io/) uses for onboarding.

:exclamation: Terraform state may contain sensitive information. Please follow best security practices when securing your state.

## Usage

```hcl
module "expel_azure_aks_integration" {
  source  = "expel-io/aks/azure"

  # Tenant ID that will be onboarded
  tenant_id = var.tenant_id
  # Subscription ID that will be onboarded
  subscription_id = var.subscription_id
  # Name of Azure AD app to create
  azure_ad_app_name = "Expel AKS Integration"
  # Name of Custom Role to create
  azure_custom_role_name = "Expel AKS Role"

}
```

Once you have configured your Azure environment, go to
https://workbench.expel.io/settings/security-devices?setupIntegration=kubernetes_aks and create an AKS
security device to enable Expel to begin monitoring your AWS environment.

## Permissions
The permissions allocated by this module allow Expel Workbench to perform investigations and discover AKS clusters in the environment.

## Limitations
1. Will always create a new Azure Active Directory application registration
2. Does not configure audit logging for your AKS clusters

See Expel's Getting Started Guide for AKS for more onboarding information.

## Issues
If you find a bug or have an idea for the next amazing feature, please create an issue. We'll get back to you as soon as we can!

## Contributing
Contributions are welcome!

1. Fork the Project
2. Create your Feature Branch (git checkout -b feature/AmazingFeature)
3. Commit your Changes (git commit -m 'Add some AmazingFeature')
4. Push to the Branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

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
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 2.33.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.40.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The Azure Subscription ID that will be onboarded with Expel Workbench. | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | The Azure Tenant ID that will be onboarded with Expel Workbench. | `string` | n/a | yes |
| <a name="input_azure_ad_app_name"></a> [azure\_ad\_app\_name](#input\_azure\_ad\_app\_name) | The name of the Azure AD app to be created. | `string` | `"Expel AKS Integration"` | no |
| <a name="input_azure_custom_role_name"></a> [azure\_custom\_role\_name](#input\_azure\_custom\_role\_name) | The name of the Azure custom IAM role to be created. | `string` | `"Expel AKS Role"` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_client_id"></a> [application\_client\_id](#output\_application\_client\_id) | Client ID of the Azure Application created for Expel |
| <a name="output_application_secret"></a> [application\_secret](#output\_application\_secret) | The application secret that allows Expel to authenticate |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | The ID of the Azure subscription where resources were created for Expel |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | The ID of the Azure tenant where resources were created for Expel |
## Resources

| Name | Type |
|------|------|
| [azuread_application.expel_azure_ad_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.expel_app_creds](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.expel_svc_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_role_assignment.expel_app_la_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.expel_app_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.expel_aks_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
<!-- end-tf-docs -->
