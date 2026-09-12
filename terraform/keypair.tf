# Par de chaves (gera a .pem localmente)
resource "tls_private_key" "korp" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "korp" {
  key_name   = var.key_name
  public_key = tls_private_key.korp.public_key_openssh

  tags = { Name = "${var.prefixo}-pem" }
}

# salva a chave privada em disco (já coberta pelo *.pem do .gitignore)
resource "local_file" "korp_pem" {
  content         = tls_private_key.korp.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}
