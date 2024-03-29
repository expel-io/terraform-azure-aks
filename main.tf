data "azuread_client_config" "current" {}

# Expel's Azure AD Application Registration
resource "azuread_application" "expel_azure_ad_app" {
  display_name     = var.azure_ad_app_name
  sign_in_audience = "AzureADMyOrg"
  logo_image       = filebase64("${path.module}/static/expel-logo.png")
  owners           = [data.azuread_client_config.current.object_id]

  web {
    homepage_url = "https://expel.com"
  }

  feature_tags {
    enterprise = false
    gallery    = false
    hide       = true
  }

  ### API Permissions granted to the app
  #
  # To resolve resource_app_id to a display name: 
  # az ad sp list --query "[?appId=='<resource_app_id>'].appDisplayName | [0]" --all
  #
  # To resolve an application (aka "Role") permission:
  # az ad sp show --id <resource_app_id> --query "oauth2PermissionScopes[?id=='<resource_access.id>']"
  #
  # To resolve a delegated (aka "Scope") permission:
  # az ad sp show --id <resource_app_id> --query "oauth2PermissionScopes[?id=='<resource_access.id>']"

  required_resource_access {
    resource_app_id = "ca7f3f0b-7d91-482c-8e09-c5d840d0eac5" # Log Analytics API

    resource_access {
      id   = "e8f6e161-84d0-4cd7-9441-2d46ec9ec3d5" // Log Analytics Data.Read permission
      type = "Role"                                 # Application Permissions
    }
  }
}

# Expel's Service Principal (tied to the AD Application)
resource "azuread_service_principal" "expel_svc_principal" {
  application_id = azuread_application.expel_azure_ad_app.application_id
}

# Creating credentials for the Expel app
resource "azuread_application_password" "expel_app_creds" {
  application_object_id = azuread_application.expel_azure_ad_app.object_id
}

# Assigning Log Analytics Reader to app
resource "azurerm_role_assignment" "expel_app_la_reader" {
  scope                = format("/subscriptions/%s", var.subscription_id)
  role_definition_name = "Log Analytics Reader"
  principal_id         = azuread_service_principal.expel_svc_principal.object_id
}

# Resource Group for the Storage Account that will store AKS logs
resource "azurerm_resource_group" "aks_logs_resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# The storage account where AKS logs will be sent
resource "azurerm_storage_account" "aks_logs_storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.aks_logs_resource_group.name
  location                 = azurerm_resource_group.aks_logs_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }
}

# Configure diagnostic logs for provided AKS clusters
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic_logs_to_storage_account" {
  for_each = toset(var.aks_clusters)

  name               = "K8sLoggingForExpel"
  target_resource_id = each.key
  storage_account_id = azurerm_storage_account.aks_logs_storage_account.id

  enabled_log {
    category = "kube-audit" # The K8s control plane logs

    retention_policy {
      enabled = true
      days    = var.retention_days
    }
  }
}

# Assigning Storage Account Data Reader to app
# Condition ensures this access is only for the provided storage account name
resource "azurerm_role_assignment" "expel_app_sa_reader" {
  scope                = format("/subscriptions/%s", var.subscription_id)
  role_definition_name = "Storage Account Data Reader"
  principal_id         = azuread_service_principal.expel_svc_principal.object_id
  condition_version    = "2.0"
  condition            = format("(\n (\n  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})\n )\n OR \n (\n  @Resource[Microsoft.Storage/storageAccounts:name] StringEquals '%s'\n )\n)", var.storage_account_name)
}

# Assigning Expel's Custom Role to app
resource "azurerm_role_assignment" "expel_app_role_assignment" {
  scope              = format("/subscriptions/%s", var.subscription_id)
  role_definition_id = azurerm_role_definition.expel_aks_role.role_definition_resource_id
  principal_id       = azuread_service_principal.expel_svc_principal.object_id
}

# Expel's AKS Custom Role (grants required permissions for AKS)
resource "azurerm_role_definition" "expel_aks_role" {
  name        = var.azure_custom_role_name
  scope       = format("/subscriptions/%s", var.subscription_id)
  description = "Allows Expel to discover AKS clusters and read non-sensitive resources"

  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/agentPools/read",
      "Microsoft.ContainerService/managedClusters/privateEndpointConnections/read",
      "Microsoft.ContainerService/managedClusters/diagnosticsState/read"
    ]
    data_actions = [
      "Microsoft.ContainerService/fleets/api/read",
      "Microsoft.ContainerService/fleets/api/v1/read",
      "Microsoft.ContainerService/fleets/apis/read",
      "Microsoft.ContainerService/fleets/apis/admissionregistration.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/admissionregistration.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/admissionregistration.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/apiextensions.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/apiextensions.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/apiextensions.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/apiregistration.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/apiregistration.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/apiregistration.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/apps/read",
      "Microsoft.ContainerService/fleets/apis/apps/v1/read",
      "Microsoft.ContainerService/fleets/apis/apps/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/apps/v1beta2/read",
      "Microsoft.ContainerService/fleets/apis/authentication.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/authentication.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/authentication.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/authorization.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/authorization.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/authorization.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/autoscaling/read",
      "Microsoft.ContainerService/fleets/apis/autoscaling/v1/read",
      "Microsoft.ContainerService/fleets/apis/autoscaling/v2beta1/read",
      "Microsoft.ContainerService/fleets/apis/autoscaling/v2beta2/read",
      "Microsoft.ContainerService/fleets/apis/batch/read",
      "Microsoft.ContainerService/fleets/apis/batch/v1/read",
      "Microsoft.ContainerService/fleets/apis/batch/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/certificates.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/certificates.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/coordination.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/coordination.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/coordination.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/events.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/events.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/extensions/read",
      "Microsoft.ContainerService/fleets/apis/extensions/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/metrics.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/metrics.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/networking.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/networking.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/networking.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/node.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/node.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/policy/read",
      "Microsoft.ContainerService/fleets/apis/policy/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/rbac.authorization.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/rbac.authorization.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/rbac.authorization.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/scheduling.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/scheduling.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/scheduling.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apis/storage.k8s.io/read",
      "Microsoft.ContainerService/fleets/apis/storage.k8s.io/v1/read",
      "Microsoft.ContainerService/fleets/apis/storage.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/fleets/apiregistration.k8s.io/apiservices/read",
      "Microsoft.ContainerService/fleets/certificates.k8s.io/certificatesigningrequests/read",
      "Microsoft.ContainerService/fleets/rbac.authorization.k8s.io/clusterrolebindings/read",
      "Microsoft.ContainerService/fleets/rbac.authorization.k8s.io/clusterroles/read",
      "Microsoft.ContainerService/fleets/componentstatuses/read",
      "Microsoft.ContainerService/fleets/apps/controllerrevisions/read",
      "Microsoft.ContainerService/fleets/batch/cronjobs/read",
      "Microsoft.ContainerService/fleets/storage.k8s.io/csidrivers/read",
      "Microsoft.ContainerService/fleets/storage.k8s.io/csinodes/read",
      "Microsoft.ContainerService/fleets/apiextensions.k8s.io/customresourcedefinitions/read",
      "Microsoft.ContainerService/fleets/apps/daemonsets/read",
      "Microsoft.ContainerService/fleets/extensions/daemonsets/read",
      "Microsoft.ContainerService/fleets/apps/deployments/read",
      "Microsoft.ContainerService/fleets/extensions/deployments/read",
      "Microsoft.ContainerService/fleets/endpoints/read",
      "Microsoft.ContainerService/fleets/events/read",
      "Microsoft.ContainerService/fleets/events.k8s.io/events/read",
      "Microsoft.ContainerService/fleets/healthz/read",
      "Microsoft.ContainerService/fleets/healthz/autoregister-completion/read",
      "Microsoft.ContainerService/fleets/healthz/etcd/read",
      "Microsoft.ContainerService/fleets/healthz/log/read",
      "Microsoft.ContainerService/fleets/healthz/ping/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/apiservice-registration-controller/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/bootstrap-controller/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/ca-registration/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/crd-informer-synced/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/start-apiextensions-informers/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.ContainerService/fleets/healthz/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.ContainerService/fleets/autoscaling/horizontalpodautoscalers/read",
      "Microsoft.ContainerService/fleets/extensions/ingresses/read",
      "Microsoft.ContainerService/fleets/networking.k8s.io/ingresses/read",
      "Microsoft.ContainerService/fleets/admissionregistration.k8s.io/initializerconfigurations/read",
      "Microsoft.ContainerService/fleets/batch/jobs/read",
      "Microsoft.ContainerService/fleets/coordination.k8s.io/leases/read",
      "Microsoft.ContainerService/fleets/limitranges/read",
      "Microsoft.ContainerService/fleets/livez/read",
      "Microsoft.ContainerService/fleets/livez/autoregister-completion/read",
      "Microsoft.ContainerService/fleets/livez/etcd/read",
      "Microsoft.ContainerService/fleets/livez/log/read",
      "Microsoft.ContainerService/fleets/livez/ping/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/apiservice-registration-controller/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/bootstrap-controller/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/ca-registration/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/crd-informer-synced/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/start-apiextensions-informers/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.ContainerService/fleets/livez/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.ContainerService/fleets/logs/read",
      "Microsoft.ContainerService/fleets/metrics/read",
      "Microsoft.ContainerService/fleets/admissionregistration.k8s.io/mutatingwebhookconfigurations/read",
      "Microsoft.ContainerService/fleets/namespaces/read",
      "Microsoft.ContainerService/fleets/extensions/networkpolicies/read",
      "Microsoft.ContainerService/fleets/networking.k8s.io/networkpolicies/read",
      "Microsoft.ContainerService/fleets/metrics.k8s.io/nodes/read",
      "Microsoft.ContainerService/fleets/nodes/read",
      "Microsoft.ContainerService/fleets/openapi/v2/read",
      "Microsoft.ContainerService/fleets/persistentvolumeclaims/read",
      "Microsoft.ContainerService/fleets/persistentvolumes/read",
      "Microsoft.ContainerService/fleets/policy/poddisruptionbudgets/read",
      "Microsoft.ContainerService/fleets/metrics.k8s.io/pods/read",
      "Microsoft.ContainerService/fleets/extensions/podsecuritypolicies/read",
      "Microsoft.ContainerService/fleets/policy/podsecuritypolicies/read",
      "Microsoft.ContainerService/fleets/podtemplates/read",
      "Microsoft.ContainerService/fleets/scheduling.k8s.io/priorityclasses/read",
      "Microsoft.ContainerService/fleets/readyz/read",
      "Microsoft.ContainerService/fleets/readyz/autoregister-completion/read",
      "Microsoft.ContainerService/fleets/readyz/etcd/read",
      "Microsoft.ContainerService/fleets/readyz/log/read",
      "Microsoft.ContainerService/fleets/readyz/ping/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/apiservice-registration-controller/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/bootstrap-controller/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/ca-registration/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/crd-informer-synced/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/start-apiextensions-informers/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.ContainerService/fleets/readyz/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.ContainerService/fleets/readyz/shutdown/read",
      "Microsoft.ContainerService/fleets/replicationcontrollers/read",
      "Microsoft.ContainerService/fleets/resetMetrics/read",
      "Microsoft.ContainerService/fleets/resourcequotas/read",
      "Microsoft.ContainerService/fleets/rbac.authorization.k8s.io/rolebindings/read",
      "Microsoft.ContainerService/fleets/rbac.authorization.k8s.io/roles/read",
      "Microsoft.ContainerService/fleets/node.k8s.io/runtimeclasses/read",
      "Microsoft.ContainerService/fleets/serviceaccounts/read",
      "Microsoft.ContainerService/fleets/services/read",
      "Microsoft.ContainerService/fleets/apps/statefulsets/read",
      "Microsoft.ContainerService/fleets/storage.k8s.io/storageclasses/read",
      "Microsoft.ContainerService/fleets/swagger-api/read",
      "Microsoft.ContainerService/fleets/swagger-ui/read",
      "Microsoft.ContainerService/fleets/ui/read",
      "Microsoft.ContainerService/fleets/admissionregistration.k8s.io/validatingwebhookconfigurations/read",
      "Microsoft.ContainerService/fleets/version/read",
      "Microsoft.ContainerService/fleets/storage.k8s.io/volumeattachments/read",
      "Microsoft.ContainerService/managedClusters/api/read",
      "Microsoft.ContainerService/managedClusters/api/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/read",
      "Microsoft.ContainerService/managedClusters/apis/admissionregistration.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/admissionregistration.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/admissionregistration.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/apiextensions.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/apiextensions.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/apiextensions.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/apiregistration.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/apiregistration.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/apiregistration.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/apps/read",
      "Microsoft.ContainerService/managedClusters/apis/apps/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/apps/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/apps/v1beta2/read",
      "Microsoft.ContainerService/managedClusters/apis/authentication.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/authentication.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/authentication.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/authorization.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/authorization.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/authorization.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/autoscaling/read",
      "Microsoft.ContainerService/managedClusters/apis/autoscaling/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/autoscaling/v2beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/autoscaling/v2beta2/read",
      "Microsoft.ContainerService/managedClusters/apis/batch/read",
      "Microsoft.ContainerService/managedClusters/apis/batch/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/batch/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/certificates.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/certificates.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/coordination.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/coordination.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/coordination.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/events.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/events.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/extensions/read",
      "Microsoft.ContainerService/managedClusters/apis/extensions/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/metrics.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/metrics.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/networking.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/networking.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/networking.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/node.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/node.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/policy/read",
      "Microsoft.ContainerService/managedClusters/apis/policy/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/rbac.authorization.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/rbac.authorization.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/rbac.authorization.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/scheduling.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/scheduling.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/scheduling.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apis/storage.k8s.io/read",
      "Microsoft.ContainerService/managedClusters/apis/storage.k8s.io/v1/read",
      "Microsoft.ContainerService/managedClusters/apis/storage.k8s.io/v1beta1/read",
      "Microsoft.ContainerService/managedClusters/apiregistration.k8s.io/apiservices/read",
      "Microsoft.ContainerService/managedClusters/certificates.k8s.io/certificatesigningrequests/read",
      "Microsoft.ContainerService/managedClusters/rbac.authorization.k8s.io/clusterrolebindings/read",
      "Microsoft.ContainerService/managedClusters/rbac.authorization.k8s.io/clusterroles/read",
      "Microsoft.ContainerService/managedClusters/componentstatuses/read",
      "Microsoft.ContainerService/managedClusters/apps/controllerrevisions/read",
      "Microsoft.ContainerService/managedClusters/batch/cronjobs/read",
      "Microsoft.ContainerService/managedClusters/storage.k8s.io/csidrivers/read",
      "Microsoft.ContainerService/managedClusters/storage.k8s.io/csinodes/read",
      "Microsoft.ContainerService/managedClusters/storage.k8s.io/csistoragecapacities/read",
      "Microsoft.ContainerService/managedClusters/apiextensions.k8s.io/customresourcedefinitions/read",
      "Microsoft.ContainerService/managedClusters/apps/daemonsets/read",
      "Microsoft.ContainerService/managedClusters/extensions/daemonsets/read",
      "Microsoft.ContainerService/managedClusters/apps/deployments/read",
      "Microsoft.ContainerService/managedClusters/extensions/deployments/read",
      "Microsoft.ContainerService/managedClusters/endpoints/read",
      "Microsoft.ContainerService/managedClusters/discovery.k8s.io/endpointslices/read",
      "Microsoft.ContainerService/managedClusters/events/read",
      "Microsoft.ContainerService/managedClusters/events.k8s.io/events/read",
      "Microsoft.ContainerService/managedClusters/flowcontrol.apiserver.k8s.io/flowschemas/read",
      "Microsoft.ContainerService/managedClusters/healthz/read",
      "Microsoft.ContainerService/managedClusters/healthz/autoregister-completion/read",
      "Microsoft.ContainerService/managedClusters/healthz/etcd/read",
      "Microsoft.ContainerService/managedClusters/healthz/log/read",
      "Microsoft.ContainerService/managedClusters/healthz/ping/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/apiservice-registration-controller/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/bootstrap-controller/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/ca-registration/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/crd-informer-synced/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/start-apiextensions-informers/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.ContainerService/managedClusters/healthz/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.ContainerService/managedClusters/autoscaling/horizontalpodautoscalers/read",
      "Microsoft.ContainerService/managedClusters/networking.k8s.io/ingressclasses/read",
      "Microsoft.ContainerService/managedClusters/extensions/ingresses/read",
      "Microsoft.ContainerService/managedClusters/networking.k8s.io/ingresses/read",
      "Microsoft.ContainerService/managedClusters/admissionregistration.k8s.io/initializerconfigurations/read",
      "Microsoft.ContainerService/managedClusters/batch/jobs/read",
      "Microsoft.ContainerService/managedClusters/coordination.k8s.io/leases/read",
      "Microsoft.ContainerService/managedClusters/limitranges/read",
      "Microsoft.ContainerService/managedClusters/livez/read",
      "Microsoft.ContainerService/managedClusters/livez/autoregister-completion/read",
      "Microsoft.ContainerService/managedClusters/livez/etcd/read",
      "Microsoft.ContainerService/managedClusters/livez/log/read",
      "Microsoft.ContainerService/managedClusters/livez/ping/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/apiservice-registration-controller/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/bootstrap-controller/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/ca-registration/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/crd-informer-synced/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/start-apiextensions-informers/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.ContainerService/managedClusters/livez/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.ContainerService/managedClusters/logs/read",
      "Microsoft.ContainerService/managedClusters/metrics/read",
      "Microsoft.ContainerService/managedClusters/admissionregistration.k8s.io/mutatingwebhookconfigurations/read",
      "Microsoft.ContainerService/managedClusters/namespaces/read",
      "Microsoft.ContainerService/managedClusters/extensions/networkpolicies/read",
      "Microsoft.ContainerService/managedClusters/networking.k8s.io/networkpolicies/read",
      "Microsoft.ContainerService/managedClusters/metrics.k8s.io/nodes/read",
      "Microsoft.ContainerService/managedClusters/nodes/read",
      "Microsoft.ContainerService/managedClusters/openapi/v2/read",
      "Microsoft.ContainerService/managedClusters/persistentvolumeclaims/read",
      "Microsoft.ContainerService/managedClusters/persistentvolumes/read",
      "Microsoft.ContainerService/managedClusters/policy/poddisruptionbudgets/read",
      "Microsoft.ContainerService/managedClusters/metrics.k8s.io/pods/read",
      "Microsoft.ContainerService/managedClusters/pods/read",
      "Microsoft.ContainerService/managedClusters/extensions/podsecuritypolicies/read",
      "Microsoft.ContainerService/managedClusters/policy/podsecuritypolicies/read",
      "Microsoft.ContainerService/managedClusters/podtemplates/read",
      "Microsoft.ContainerService/managedClusters/scheduling.k8s.io/priorityclasses/read",
      "Microsoft.ContainerService/managedClusters/flowcontrol.apiserver.k8s.io/prioritylevelconfigurations/read",
      "Microsoft.ContainerService/managedClusters/readyz/read",
      "Microsoft.ContainerService/managedClusters/readyz/autoregister-completion/read",
      "Microsoft.ContainerService/managedClusters/readyz/etcd/read",
      "Microsoft.ContainerService/managedClusters/readyz/log/read",
      "Microsoft.ContainerService/managedClusters/readyz/ping/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/apiservice-registration-controller/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/bootstrap-controller/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/ca-registration/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/crd-informer-synced/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/start-apiextensions-informers/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.ContainerService/managedClusters/readyz/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.ContainerService/managedClusters/readyz/shutdown/read",
      "Microsoft.ContainerService/managedClusters/apps/replicasets/read",
      "Microsoft.ContainerService/managedClusters/extensions/replicasets/read",
      "Microsoft.ContainerService/managedClusters/replicationcontrollers/read",
      "Microsoft.ContainerService/managedClusters/resetMetrics/read",
      "Microsoft.ContainerService/managedClusters/resourcequotas/read",
      "Microsoft.ContainerService/managedClusters/rbac.authorization.k8s.io/rolebindings/read",
      "Microsoft.ContainerService/managedClusters/rbac.authorization.k8s.io/roles/read",
      "Microsoft.ContainerService/managedClusters/node.k8s.io/runtimeclasses/read",
      "Microsoft.ContainerService/managedClusters/serviceaccounts/read",
      "Microsoft.ContainerService/managedClusters/services/read",
      "Microsoft.ContainerService/managedClusters/apps/statefulsets/read",
      "Microsoft.ContainerService/managedClusters/storage.k8s.io/storageclasses/read",
      "Microsoft.ContainerService/managedClusters/swagger-api/read",
      "Microsoft.ContainerService/managedClusters/swagger-ui/read",
      "Microsoft.ContainerService/managedClusters/ui/read",
      "Microsoft.ContainerService/managedClusters/admissionregistration.k8s.io/validatingwebhookconfigurations/read",
      "Microsoft.ContainerService/managedClusters/version/read",
      "Microsoft.ContainerService/managedClusters/storage.k8s.io/volumeattachments/read"
    ]
  }

  assignable_scopes = [
    format("/subscriptions/%s", var.subscription_id)
  ]
}