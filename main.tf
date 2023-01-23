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
      "Microsoft.Kubernetes/connectedClusters/Read",
      "Microsoft.Kubernetes/connectedClusters/listClusterUserCredential/action"
    ]
    data_actions = [
      "Microsoft.Kubernetes/connectedClusters/api/read",
      "Microsoft.Kubernetes/connectedClusters/api/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/read",
      "Microsoft.Kubernetes/connectedClusters/apis/admissionregistration.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/admissionregistration.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/admissionregistration.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apiextensions.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apiextensions.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apiextensions.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apiregistration.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apiregistration.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apiregistration.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apps/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apps/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/apps/v1beta2/read",
      "Microsoft.Kubernetes/connectedClusters/apis/authentication.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/authentication.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/authentication.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/authorization.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/authorization.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/authorization.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/autoscaling/read",
      "Microsoft.Kubernetes/connectedClusters/apis/autoscaling/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/autoscaling/v2beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/autoscaling/v2beta2/read",
      "Microsoft.Kubernetes/connectedClusters/apis/batch/read",
      "Microsoft.Kubernetes/connectedClusters/apis/batch/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/batch/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/coordination.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/coordination.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/coordination.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/events.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/events.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/extensions/read",
      "Microsoft.Kubernetes/connectedClusters/apis/extensions/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/metrics.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/metrics.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/networking.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/networking.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/networking.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/node.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/node.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/policy/read",
      "Microsoft.Kubernetes/connectedClusters/apis/policy/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/rbac.authorization.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/rbac.authorization.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/rbac.authorization.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/scheduling.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/scheduling.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/scheduling.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/storage.k8s.io/read",
      "Microsoft.Kubernetes/connectedClusters/apis/storage.k8s.io/v1/read",
      "Microsoft.Kubernetes/connectedClusters/apis/storage.k8s.io/v1beta1/read",
      "Microsoft.Kubernetes/connectedClusters/apiregistration.k8s.io/apiservices/read",
      "Microsoft.Kubernetes/connectedClusters/certificates.k8s.io/certificatesigningrequests/read",
      "Microsoft.Kubernetes/connectedClusters/rbac.authorization.k8s.io/clusterrolebindings/read",
      "Microsoft.Kubernetes/connectedClusters/rbac.authorization.k8s.io/clusterroles/read",
      "Microsoft.Kubernetes/connectedClusters/componentstatuses/read",
      "Microsoft.Kubernetes/connectedClusters/apps/controllerrevisions/read",
      "Microsoft.Kubernetes/connectedClusters/batch/cronjobs/read",
      "Microsoft.Kubernetes/connectedClusters/storage.k8s.io/csidrivers/read",
      "Microsoft.Kubernetes/connectedClusters/storage.k8s.io/csinodes/read",
      "Microsoft.Kubernetes/connectedClusters/apiextensions.k8s.io/customresourcedefinitions/read",
      "Microsoft.Kubernetes/connectedClusters/apps/daemonsets/read",
      "Microsoft.Kubernetes/connectedClusters/extensions/daemonsets/read",
      "Microsoft.Kubernetes/connectedClusters/apps/deployments/read",
      "Microsoft.Kubernetes/connectedClusters/extensions/deployments/read",
      "Microsoft.Kubernetes/connectedClusters/endpoints/read",
      "Microsoft.Kubernetes/connectedClusters/events/read",
      "Microsoft.Kubernetes/connectedClusters/events.k8s.io/events/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/autoregister-completion/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/etcd/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/log/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/ping/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/apiservice-registration-controller/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/bootstrap-controller/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/ca-registration/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/crd-informer-synced/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/start-apiextensions-informers/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.Kubernetes/connectedClusters/healthz/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.Kubernetes/connectedClusters/autoscaling/horizontalpodautoscalers/read",
      "Microsoft.Kubernetes/connectedClusters/extensions/ingresses/read",
      "Microsoft.Kubernetes/connectedClusters/networking.k8s.io/ingresses/read",
      "Microsoft.Kubernetes/connectedClusters/admissionregistration.k8s.io/initializerconfigurations/read",
      "Microsoft.Kubernetes/connectedClusters/batch/jobs/read",
      "Microsoft.Kubernetes/connectedClusters/coordination.k8s.io/leases/read",
      "Microsoft.Kubernetes/connectedClusters/limitranges/read",
      "Microsoft.Kubernetes/connectedClusters/livez/read",
      "Microsoft.Kubernetes/connectedClusters/livez/autoregister-completion/read",
      "Microsoft.Kubernetes/connectedClusters/livez/etcd/read",
      "Microsoft.Kubernetes/connectedClusters/livez/log/read",
      "Microsoft.Kubernetes/connectedClusters/livez/ping/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/apiservice-registration-controller/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/bootstrap-controller/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/ca-registration/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/crd-informer-synced/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/start-apiextensions-informers/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.Kubernetes/connectedClusters/livez/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.Kubernetes/connectedClusters/logs/read",
      "Microsoft.Kubernetes/connectedClusters/metrics/read",
      "Microsoft.Kubernetes/connectedClusters/admissionregistration.k8s.io/mutatingwebhookconfigurations/read",
      "Microsoft.Kubernetes/connectedClusters/namespaces/read",
      "Microsoft.Kubernetes/connectedClusters/extensions/networkpolicies/read",
      "Microsoft.Kubernetes/connectedClusters/networking.k8s.io/networkpolicies/read",
      "Microsoft.Kubernetes/connectedClusters/metrics.k8s.io/nodes/read",
      "Microsoft.Kubernetes/connectedClusters/nodes/read",
      "Microsoft.Kubernetes/connectedClusters/openapi/v2/read",
      "Microsoft.Kubernetes/connectedClusters/persistentvolumeclaims/read",
      "Microsoft.Kubernetes/connectedClusters/persistentvolumes/read",
      "Microsoft.Kubernetes/connectedClusters/policy/poddisruptionbudgets/read",
      "Microsoft.Kubernetes/connectedClusters/metrics.k8s.io/pods/read",
      "Microsoft.Kubernetes/connectedClusters/pods/read",
      "Microsoft.Kubernetes/connectedClusters/extensions/podsecuritypolicies/read",
      "Microsoft.Kubernetes/connectedClusters/policy/podsecuritypolicies/read",
      "Microsoft.Kubernetes/connectedClusters/podtemplates/read",
      "Microsoft.Kubernetes/connectedClusters/scheduling.k8s.io/priorityclasses/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/autoregister-completion/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/etcd/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/log/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/ping/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/apiservice-openapi-controller/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/apiservice-registration-controller/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/apiservice-status-available-controller/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/bootstrap-controller/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/rbac/bootstrap-roles/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/scheduling/bootstrap-system-priority-classes/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/ca-registration/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/crd-informer-synced/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/generic-apiserver-start-informers/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/kube-apiserver-autoregistration/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/start-apiextensions-controllers/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/start-apiextensions-informers/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/start-kube-aggregator-informers/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/poststarthook/start-kube-apiserver-admission-initializer/read",
      "Microsoft.Kubernetes/connectedClusters/readyz/shutdown/read",
      "Microsoft.Kubernetes/connectedClusters/apps/replicasets/read",
      "Microsoft.Kubernetes/connectedClusters/extensions/replicasets/read",
      "Microsoft.Kubernetes/connectedClusters/replicationcontrollers/read",
      "Microsoft.Kubernetes/connectedClusters/resetMetrics/read",
      "Microsoft.Kubernetes/connectedClusters/resourcequotas/read",
      "Microsoft.Kubernetes/connectedClusters/rbac.authorization.k8s.io/rolebindings/read",
      "Microsoft.Kubernetes/connectedClusters/rbac.authorization.k8s.io/roles/read",
      "Microsoft.Kubernetes/connectedClusters/node.k8s.io/runtimeclasses/read",
      "Microsoft.Kubernetes/connectedClusters/serviceaccounts/read",
      "Microsoft.Kubernetes/connectedClusters/services/read",
      "Microsoft.Kubernetes/connectedClusters/apps/statefulsets/read",
      "Microsoft.Kubernetes/connectedClusters/storage.k8s.io/storageclasses/read",
      "Microsoft.Kubernetes/connectedClusters/swagger-api/read",
      "Microsoft.Kubernetes/connectedClusters/swagger-ui/read",
      "Microsoft.Kubernetes/connectedClusters/ui/read",
      "Microsoft.Kubernetes/connectedClusters/admissionregistration.k8s.io/validatingwebhookconfigurations/read",
      "Microsoft.Kubernetes/connectedClusters/version/read",
      "Microsoft.Kubernetes/connectedClusters/storage.k8s.io/volumeattachments/read"
    ]
  }

  assignable_scopes = [
    format("/subscriptions/%s", var.subscription_id)
  ]
}