variable "namespaces_with_policies" {
  description = "Namespaces to apply network policies to"
  type        = list(string)
  default     = []
}
