resource "kubernetes_deployment" "kube-state-metrics" {

  metadata {
    labels = {
      k8s-app = "kube-state-metrics"
    }
    name = "kube-state-metrics"
    namespace = "kube-system"
  }
  spec {

    selector {
      match_labels = {
        k8s-app = "kube-state-metrics"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          k8s-app = "kube-state-metrics"
        }
      }
      spec {
        service_account_name = "kube-state-metrics"
        volume {
          name = "${kubernetes_service_account.kube-state-metrics.default_secret_name}"

          secret {
            secret_name = "${kubernetes_service_account.kube-state-metrics.default_secret_name}"
          }
        }
        container {
          name = "kube-state-metrics"
          image = "quay.io/coreos/kube-state-metrics:v1.7.1"

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "${kubernetes_service_account.kube-state-metrics.default_secret_name}"
            read_only  = true
          }

          port {
            name = "http-metrics"
            container_port = 8080
          }
          port {
            name = "telemetry"
            container_port = 8081
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            timeout_seconds = 5

          }
        }
      }
    }
  }
}
