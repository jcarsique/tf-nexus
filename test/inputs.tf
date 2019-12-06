variable region {
  type    = "string"
  default = "eu-west-1"
}

variable "environment" {
  default = "test"
  type    = "string"
}

variable "namespace" {
  type    = "string"
  default = "devops-tools-test"
}

variable "kubeconfig-file" {
  default = "./kubeconfig.yaml"
}

variable "default_tags" {
  type = "map"
  default = {
    "billing-category"    = "build"
    "billing-subcategory" = "nexus"
    "environment"         = "test"
    "project"             = "nexus-central"
  }
}

variable "cluster-name" {
  default = "terraform-eks-nexus-central-test"
  type    = "string"
}

variable "nexus_image" {
  type    = "string"
  default = "dockerpriv.nuxeo.com:443/devtools/nexus3/central:preprod"
}

variable "pod-replicas" {
  default = "3"
}

variable ec2_instance_type {
  type = "string"
  default = "m4.2xlarge"
}

variable route53_dns_name {
  type = "map"
  default = {
    "docker-registry" = "docker-test.packages.nuxeo.com"
    "nexus-iq" = "iq-test.packages.nuxeo.com"
    "nexus-central" = "staging.packages.nuxeo.com"
  }
}

variable container_resources_nexus {
  type = "map"
  default = {
    limits_memory: "16Gi"
    limits_cpu: "3.5"
    requests_memory: "8Gi"
    requests_cpu: "3"
  }
}
variable debug_hazelcast {
  type = bool
  default = true
}