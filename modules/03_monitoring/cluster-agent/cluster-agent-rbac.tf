
resource "kubernetes_cluster_role" "datadog-cluster-agent" {

  metadata {
    name = "datadog-cluster-agent"
  }

  rule {
    api_groups = [""]
    resources = ["services",
      "events",
      "endpoints",
      "pods",
      "nodes",
    "componentstatuses"]
    verbs = ["get",
      "list",
    "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["datadogtoken", "datadog-leader-election"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "get", "update"]
  }

  rule {
    non_resource_urls = ["/version", "/healthz"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "datadog-cluster-agent" {

  metadata {
    name = "datadog-cluster-agent"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "datadog-cluster-agent"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "datadog-cluster-agent"
    namespace = "default"
  }
}

resource "kubernetes_service_account" "datadog-cluster-agent" {

  metadata {
    name      = "datadog-cluster-agent"
    namespace = "default"
  }
}
