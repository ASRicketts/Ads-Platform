variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  type = string
}