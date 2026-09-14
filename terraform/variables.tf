# Declaração das variáveis — sem valores aqui.
# Os valores ficam no terraform.tfvars (gitignored) e no terraform.tfvars.example.

variable "region" {
  description = "Região da AWS"
  type        = string
}

variable "prefixo" {
  description = "Prefixo usado no nome de todos os recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC existente onde a instância e o security group serão criados"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública que será criada na VPC existente"
  type        = string
}

variable "az" {
  description = "Availability Zone da subnet pública"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância"
  type        = string
}

variable "ami_id" {
  description = "AMI Ubuntu amd64"
  type        = string
}

variable "key_name" {
  description = "Nome do par de chaves"
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR do IP com acesso total (SSH e painéis)"
  type        = string
}

variable "eip_public_ip" {
  description = "IP elástico existente que será reaproveitado"
  type        = string
}

variable "cloudflare_cidrs" {
  description = "Faixas de IP do Cloudflare (https://www.cloudflare.com/ips/)"
  type        = list(string)
}

variable "github_repo" {
  description = "Repositório (owner/nome) pra registrar o runner self-hosted"
  type        = string
}

variable "github_runner_token_parameter_name" {
  description = "Nome do parâmetro SecureString no SSM que contém o token de registro do runner"
  type        = string
}

variable "github_runner_token_parameter_arn" {
  description = "ARN do parâmetro SecureString no SSM que contém o token de registro do runner"
  type        = string
}

variable "loki_s3_bucket" {
  description = "Bucket S3 existente usado pelo Loki para persistir chunks e índices"
  type        = string
  default     = "cn-korp-loki-logs-us-east-1"
}


variable "runner_name" {
  description = "Nome do runner self-hosted"
  type        = string
  default     = "korp-runner"
}

variable "runner_version" {
  description = "Versão do runner do GitHub Actions"
  type        = string
  default     = "2.337.0"
}
