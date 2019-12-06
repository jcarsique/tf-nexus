variable "datadog_file" {
  type        = "string"
  default     = ".datadog_key"
  description = "Datadog API key"
}

variable "cluster-agent-token" {
  type        = "string"
  default     = ".cluster-agent-token"
  description = "Datadog cluster agent token "
}
