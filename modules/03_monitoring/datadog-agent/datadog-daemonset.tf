resource "kubernetes_daemonset" "datadog_daemonset" {

  metadata {
    name = "datadog-daemonset"
    labels = {
      app  = "datadog-agent"
      name = "datadog-agent"
    }
  }

  spec {

    selector {
      match_labels = {
        app = "datadog-agent"
      }
    }

    template {

      metadata {
        labels = {
          app = "datadog-agent"
        }
        name = "datadog-agent"
      }

      spec {

        service_account_name = "datadog-agent"
        volume {
          name = "${kubernetes_service_account.datadog-agent.default_secret_name}"
          secret {
            secret_name = "${kubernetes_service_account.datadog-agent.default_secret_name}"
          }
        }
        container {
          image             = "datadog/agent:latest"
          image_pull_policy = "Always"
          name              = "datadog-agent"

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "${kubernetes_service_account.datadog-agent.default_secret_name}"
            read_only  = true
          }

          port {
            container_port = 8125
            name           = "dogstatsdprot"
            protocol       = "UDP"
          }

          port {
            container_port = 8126
            name           = "traceport"
            protocol       = "TCP"
          }

          env {
            name  = "DD_COLLECT_KUBERNETES_EVENTS"
            value = "true"
          }

          env {
            name = "DD_API_KEY"
            value_from {
              secret_key_ref {
                name = "${var.datadog-config}"
                key  = "DD_API_KEY"
              }
            }
          }

          env {
            name  = "DD_LEADER_ELECTION"
            value = "true"
          }

          env {
            name  = "KUBERNETES"
            value = "yes"
          }

          env {
            name = "DD_KUBERNETES_KUBELET_HOST"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name  = "DD_LOGS_ENABLED"
            value = "true"
          }

          env {
            name  = "DD_CLUSTER_NAME"
            value = "EKS-Nexus"
          }
          env {
            name  = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL"
            value = "true"
          }

          env {
            name  = "DD_CLUSTER_AGENT_ENABLED"
            value = "true"
          }

          env {
            ## Need to mount volume
            name = "DD_CLUSTER_AGENT_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = "${var.cluster-token}"
                key  = "token"
              }
            }
          }
          env {
            name  = "DD_AC_EXCLUDE"
            value = "name:datadog-agent"
          }

          resources {
            requests {
              memory = "256Mi"
              cpu    = "200m"
            }
            limits {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          volume_mount {
            name       = "dockersocket"
            mount_path = "/var/run/docker.sock"
          }

          volume_mount {
            name       = "procdir"
            mount_path = "/host/proc"
            read_only  = true
          }

          volume_mount {
            name       = "cgroups"
            mount_path = "/host/sys/fs/cgroup"
            read_only  = true
          }

          volume_mount {
            name       = "pointerdir"
            mount_path = "/opt/datadog-agent/run"
          }

          liveness_probe {
            exec {
              command = ["./probe.sh"]
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
        volume {
          name = "dockersocket"
          host_path {
            path = "/var/run/docker.sock"
          }
        }

        volume {
          name = "procdir"
          host_path {
            path = "/proc"
          }
        }

        volume {
          name = "cgroups"
          host_path {
            path = "/sys/fs/cgroup"
          }
        }

        volume {
          name = "pointerdir"
          host_path {
            path = "/opt/datadog-agent/run"
          }
        }
      }
    }
  }
}
