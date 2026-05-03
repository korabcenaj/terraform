variable "namespace" {
  description = "The namespace to deploy PostgreSQL into."
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL username."
  type        = string
  default     = "immich"
}

variable "postgres_password" {
  description = "PostgreSQL password."
  type        = string
}

variable "postgres_db" {
  description = "PostgreSQL database name."
  type        = string
  default     = "immich"
}
