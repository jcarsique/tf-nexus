resource "kubernetes_namespace" "nexus-namespace" {
  metadata {
    name = "${var.namespace}"
  }
}

resource "kubernetes_config_map" "nexus-configmap" {
  metadata {
    name      = "${var.cluster-name}-configmap"
    namespace = "${var.namespace}"
  }

  binary_data = {
    ".license.lic" = "${filebase64(var.nexus_license)}"
  }
}

resource "kubernetes_config_map" "nexus-hazelcast-configmap" {
  metadata {
    name      = "${var.cluster-name}-hazelcast-configmap"
    namespace = "${var.namespace}"
  }

  data = {
    "hazelcast-network.xml" = "${file(var.nexus_hazelcast)}"
  }
}


resource "kubernetes_stateful_set" "nexus" {
  metadata {
    name      = "${var.cluster-name}-pod"
    namespace = "${var.namespace}"

    labels = {
      app = "nexus-central"
    }
  }

  spec {
    service_name = "nexus"
    replicas     = "${var.pod_replicas}"

    selector {
      match_labels = {
        app = "nexus-central"
      }
    }

    template {
      metadata {
        labels      = {
          app = "nexus-central"
        }
        annotations = {
          "ad.datadoghq.com/nexus.logs" = "source: nexus, service: nexus"
        }
      }

      spec {
        image_pull_secrets {
          name = "${kubernetes_secret.regsecret.metadata.0.name}"
        }


        security_context {
          fs_group = 200
        }
        
        init_container {
          name    = "volume-mount-hack"
          image   = "busybox"
          command = [
            "sh",
            "-c",
            "chown -R 200:200 /nexus-data"]
          volume_mount {
            mount_path = "/nexus-data"
            name       = "nexus-data"

          }
        }

        container {
          image             = "${var.nexus_image}"
          image_pull_policy = "Always"
          name              = "nexus3"

          lifecycle {
            post_start {
              exec {
                command = [
                  "/opt/sonatype/nexus/postStart.sh"]
              }
            }
          }

          port {
            container_port = 8081
          }
          port {
            container_port = 5000
          }
          port {
            container_port = 5701
          }
          port {
            container_port = 5702
          }
          port {
            container_port = 5703
          }
          resources {
            limits {
              cpu    = "${var.container_resources_nexus.limits_cpu}"
              memory = "${var.container_resources_nexus.limits_memory}"
            }
            requests {
              cpu    = "${var.container_resources_nexus.requests_cpu}"
              memory = "${var.container_resources_nexus.requests_memory}"
            }
          }

          volume_mount {
            mount_path = "/nexus-data"
            name       = "nexus-data"
          }

          volume_mount {
            mount_path = "/nexus-data/etc/fabric/hazelcast-network.xml"
            sub_path   = "hazelcast-network.xml"
            name       = "nexus-ha-config"
          }

          volume_mount {
            mount_path = "/nexus-data/etc/license/.license.lic"
            name       = "nexus-license-file"
            sub_path   = ".license.lic"
          }

          env {
            name  = "INSTALL4J_ADD_VM_PARAMS"
            value = "-Xms4G -Xmx4G -XX:MaxDirectMemorySize=17530M -Dhazelcast.diagnostics.enabled=${var.debug_hazelcast}"
          }
          env {
            name  = "ulimit"
            value = "nofile=65536:65536"
          }
        }

        volume {
          name = "nexus-data"
          persistent_volume_claim {
            claim_name = "nexus-data"
          }
        }

        volume {
          name = "nexus-license-file"
          config_map {
            name = "${kubernetes_config_map.nexus-configmap.metadata.0.name}"
            items {
              key  = ".license.lic"
              path = ".license.lic"
            }
          }
        }

        volume {
          name = "nexus-ha-config"
          config_map {
            name = "${kubernetes_config_map.nexus-hazelcast-configmap.metadata.0.name}"
            items {
              key  = "hazelcast-network.xml"
              path = "hazelcast-network.xml"
            }
          }
        }
      }
    }

    update_strategy {
      type = "RollingUpdate"
    }

    volume_claim_template {
      metadata {
        name      = "nexus-data"
        namespace = "${var.namespace}"
      }
      spec {
        access_modes = [
          "ReadWriteOnce"]

        resources {
          requests = {
            storage = "${var.storage_size}"
          }
        }
      }
    }
  }
}

resource "kubernetes_storage_class" "storage" {
  storage_provisioner = "kubernetes.io/aws-ebs"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete"

  parameters = {
    type = "gp2"
    encrypted = "true"
  }

  metadata {
    name = "${var.cluster-name}-gp2"
  }
}
