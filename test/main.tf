terraform {
  backend "s3" {
    bucket  = "nuxeo-devtools-terraform"
    key     = "nexus-central-test/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

module "network" {
  source             = "../modules/01_network"
  environment        = "${var.environment}"
  region             = "${var.region}"
  default_tags       = "${var.default_tags}"
  cluster-name       = "${var.cluster-name}"
  ec2_instance_type  = "${var.ec2_instance_type}"
  route53_dns_name   = "${var.route53_dns_name}"
  aws_lb_listener_certificate_arn = "${var.aws_lb_listener_certificate_arn}"
}

module "kubernetes" {
  source                    = "../modules/02_kubernetes"
  kubeconfig-file           = "${var.kubeconfig-file}"
  pod_replicas              = "${var.pod-replicas}"
  default_tags              = "${var.default_tags}"
  nexus_image               = "${var.nexus_image}"
  namespace                 = "${var.namespace}"
  cluster-name              = "${var.cluster-name}"
  container_resources_nexus = "${var.container_resources_nexus}"
}
