variable "aws_region" {
  description = "Regiao AWS utilizada na Atividade 6."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefixo dos recursos."
  type        = string
  default     = "atividade6"
}

variable "db_name" {
  description = "Nome do banco PostgreSQL."
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "Usuario administrador PostgreSQL."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do PostgreSQL. Nao versionar o valor real."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instancia RDS para reproducao do laboratorio."
  type        = string
  default     = "db.t4g.micro"
}
