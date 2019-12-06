resource "kubernetes_cluster_role" "datadog-agent" {


  metadata {
    name = "datadog-agent"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/metrics", "nodes/spec", "nodes/proxy"]
    verbs      = ["get"]
  }

}

resource "kubernetes_service_account" "datadog-agent" {

  metadata {
    name      = "datadog-agent"
    namespace = "default"
  }
}

resource "kubernetes_cluster_role_binding" "datadog-agent" {

  metadata {
    name = "datadog-agent"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "datadog-agent"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "datadog-agent"
    namespace = "default"
  }
}
