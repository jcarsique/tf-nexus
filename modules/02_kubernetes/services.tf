resource "kubernetes_service" "nexus" {
  metadata {
    name        = "terraform-devops-tools"
    namespace   = "${var.namespace}"
    labels      = {
      app = "nexus-central"
    }

  }

  spec {
    type                    = "NodePort"
    selector                = {
      app = "nexus-central"
    }
    session_affinity        = "ClientIP"

    port {
      name        = "web"
      port        = 80
      target_port = 8081
      node_port   = 32000
    }
    port {
      name        = "docker"
      port        = 5000
      target_port = 5000
      node_port   = 32021
    }
    port {
      name        = "arender"
      port        = 5001
      target_port = 5001
      node_port   = 32022
    }
    port {
      name        = "docker-private"
      port        = 6000
      target_port = 6000
      node_port   = 32020
    }
  }
}

resource "kubernetes_service" "nexusiq" {
  metadata {
    name      = "terraform-devops-tools-nexusiq"
    namespace = "${var.namespace}"
    labels    = {
      k8s-app = "nexusiq"
    }
  }

  spec {
    type     = "NodePort"
    selector = {
      k8s-app = "nexusiq"
    }
    port {
      name        = "app"
      port        = 8070
      target_port = 8070
      node_port   = 32010
    }
    port {
      name        = "admin"
      port        = 8071
      target_port = 8071
      node_port   = 32011
    }
  }
}
