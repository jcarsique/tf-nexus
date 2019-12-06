output "kubeconfig" {
  value = "${module.network.kubeconfig}"
}

output "config-map-aws" {
  value = "${module.network.config_map_aws_auth}"
}
