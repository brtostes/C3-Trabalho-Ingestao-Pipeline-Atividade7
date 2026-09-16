variable "aws_region" {
  description = "Regiao AWS."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo dos recursos."
  type        = string
  default     = "atividade6-pipeline"
}

variable "db_name" {
  description = "Nome do banco PostgreSQL."
  type        = string
  default     = "atividade6"
}

variable "db_username" {
  description = "Usuario administrador PostgreSQL."
  type        = string
  default     = "atividade6"
}

variable "db_password" {
  description = "Senha do PostgreSQL. Use valor forte."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instancia RDS."
  type        = string
  default     = "db.t4g.micro"
}
