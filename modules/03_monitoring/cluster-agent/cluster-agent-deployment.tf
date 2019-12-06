resource "kubernetes_deployment" "datadog-cluster-agent" {

  metadata {
    name      = "datadog-cluster-agent"
    namespace = "default"
  }

  spec {

    selector {
      match_labels = {
        app = "datadog-cluster-agent"
      }
    }

    template {

      metadata {
        labels = {
          app = "datadog-cluster-agent"
        }
        name = "datadog-agent"
      }

      spec {
        service_account_name = "datadog-cluster-agent"
        volume {
          name = "${kubernetes_service_account.datadog-cluster-agent.default_secret_name}"
          secret {
            secret_name = "${kubernetes_service_account.datadog-cluster-agent.default_secret_name}"
          }
        }
        container {
          image             = "datadog/cluster-agent:latest"
          image_pull_policy = "Always"
          name              = "datadog-cluster-agent"
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "${kubernetes_service_account.datadog-cluster-agent.default_secret_name}"
            read_only  = true
          }

          env {
            name = "DD_API_KEY"
            value_from {
              secret_key_ref {
                name = "${kubernetes_secret.datadog-config.metadata.0.name}"
                key  = "DD_API_KEY"
              }
            }
          }

          env {
            name  = "DD_COLLECT_KUBERNETES_EVENTS"
            value = "true"
          }

          env {
            name  = "DD_LEADER_ELECTION"
            value = "true"
          }

          env {
            name  = "DD_EXTERNAL_METRICS_PROVIDER_ENABLED"
            value = "true"
          }
          env {
            name = "DD_CLUSTER_AGENT_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = "datadog-auth-token"
                key  = "token"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "datadog-cluster-agent" {


  metadata {
    name = "datadog-cluster-agent"
    labels = {
      app = "datadog-cluster-agent"
    }
  }
  spec {
    port {
      port     = 5005
      protocol = "TCP"
    }
    selector = {
      app = "datadog-cluster-agent"
    }
  }
}
