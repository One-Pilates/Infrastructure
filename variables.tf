# ============================================================
# Variables - OnePilates AWS Infrastructure
# ============================================================

variable "aws_region" {
  description = "Região AWS para deploy da infraestrutura"
  type        = string
  default     = "us-east-1"
}

variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "onepilates"
}

variable "ami_id" {
  description = "AMI ID para as instâncias EC2 (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
}

variable "instance_type_proxy" {
  description = "Tipo de instância para o proxy"
  type        = string
  default     = "t2.micro"
}

variable "instance_type_app" {
  description = "Tipo de instância para servidores de aplicação"
  type        = string
  default     = "t2.micro"
}

variable "instance_type_db" {
  description = "Tipo de instância para o banco de dados"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nome do Key Pair para acesso SSH às instâncias"
  type        = string
  default     = "onepilates-key"
}

variable "meu_ip" {
  description = "Seu IP público para acesso SSH (formato: x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0" # Alterar para seu IP real em produção
}
