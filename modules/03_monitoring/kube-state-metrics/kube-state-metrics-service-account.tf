resource "kubernetes_service_account" "kube-state-metrics" {

  metadata {
    name = "kube-state-metrics"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}
