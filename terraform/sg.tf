# Security group (mesmas regras do SG atual do desafio)
resource "aws_security_group" "korp" {
  name        = "${var.prefixo}-sg"
  description = "SG do desafio Korp"
  vpc_id      = var.vpc_id

  ingress {
    description = "Cloudflare na porta 80 (proxied)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cloudflare_cidrs
  }

  ingress {
    description = "Acesso total do meu IP (SSH, Grafana, Prometheus)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.prefixo}-sg" }
}
