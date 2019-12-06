provider "kubernetes" {
  config_path = "${var.kubeconfig-file}"
}

provider "aws" {
}

resource "kubernetes_secret" "regsecret" {
}

resource "kubernetes_secret" "nexus-config" {
}
