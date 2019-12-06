variable "datadog-config" {
  type = "string"
  default = "datadog-config-secret"
  description = "Datadog API Key"
}

variable "cluster-token" {
  type = "string"
  default = "datadog-auth-token"
  description = "Datadog agent token"
}
