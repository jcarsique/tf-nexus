resource "kubernetes_service" "kube-state-metrics" {

  metadata {
    name = "kube-state-metrics"
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-state-metrics"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }
  spec {
    port {
      name = "http-metrics"
      port = 8080
      target_port = "http-metrics"
      protocol = "TCP"
    }
    port {
      name = "telemetry"
      port = 8081
      target_port = "telemetry"
      protocol = "TCP"
    }

    selector = {
      k8s-app = "kube-state-metrics"
    }
  }
}
