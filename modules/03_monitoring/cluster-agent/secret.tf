resource "kubernetes_secret" "datadog-config" {
  metadata {
    name = "datadog-config-secret"
  }

  data = {
    DD_API_KEY = "${file(var.datadog_file)}"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "cluster-agent-token" {

  metadata {
    name = "datadog-auth-token"
  }

  data = {
    token = "${file(var.cluster-agent-token)}"
  }

  type = "Opaque"
}
