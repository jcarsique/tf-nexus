# kubernetes versions before 1.8.0 should use rbac.authorization.k8s.io/v1beta1

resource "kubernetes_cluster_role_binding" "kube-state-metrics" {

  metadata {
    name = "kube-state-metrics"

  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "kube-state-metrics"
  }
  subject {
    kind = "ServiceAccount"
    name = "kube-state-metrics"
    namespace = "kube-system"
  }
}
