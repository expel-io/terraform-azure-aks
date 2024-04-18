# Basic AKS Integration Example

This configuration sets up appropriate Azure resources that are necessary to integrate Expel Workbench with existing AKS clusters in a project.

This `Basic` example is the simplest onboarding experience, as it assumes a single Azure tenant is being onboarded.

## Table of Contents

- [Usage](#usage)
- [Variables](#variables)
- [Provider](#provider)
- [Module](#module)
- [Output](#output)
- [Prerequisites](#prerequisites)

## Variables

`tenant_id` - The Azure tenant ID where the AKS cluster is located.
`subscription_id` - The Azure subscription ID where the AKS cluster is located.
`resource_group_name` - The name of the resource group where the AKS cluster is located.
`resource_group_location` - The location of the resource group where the AKS cluster is located.
`storage_account_name` - The name of the storage account to be created.
`aks_clusters` - The list of AKS clusters to configure diagnostics for.

## Provider

- `azuread` - The Azure Active Directory provider is used to create a service principal for the Azure resources.
- `azurerm` - The Azure Resource Manager provider is used to create the necessary Azure resources.

## Module

`expel_azure_aks_integration` - This module creates the necessary Azure resources to integrate Expel Workbench with an existing AKS cluster.

## Output

`expel_azure_aks_integration` - This output variable contains the values of the resources created by the module. Due to the `sensitive` attribute being set to `true`, the output values will not be displayed in the console or logs to prevent exposure of potentially sensitive information. However, please note that these values will still be stored in the Terraform state file, which should be securely managed.

## Usage

Follow these steps to deploy the configuration:

1. Initialize Terraform in your working directory. This will download the necessary provider plugins.
2. Apply the Terraform configuration. Ensure you have a `terraform.tfvars` file in your working directory with all the necessary variables:

```shell
terraform init
terraform apply -var-file="terraform.tfvars"
```

> **Note**: Sensitive data like the service account key isn't displayed in the standard output. However, it's stored in the statefile. Ensure the statefile and its secrets are secured.

 To view the service account key created, run:

```shell
terraform output -json
```

> **Note**: This configuration may create resources that incur costs (pub/sub queue, for example). To avoid unnecessary charges, run the `terraform destroy` command to remove these resources when they are no longer needed.

## Prerequisites

| Name | Version |
|------|---------|
| terraform | >= 1.1.0 |
| azuread | ~> 2.33.0 |