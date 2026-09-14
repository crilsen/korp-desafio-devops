# Subnet pública criada dentro da VPC informada.
resource "aws_subnet" "korp" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.prefixo}-subnet" }
}
