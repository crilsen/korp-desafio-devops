# Usa o Internet Gateway já associado à VPC existente.
data "aws_internet_gateway" "korp" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_route_table" "korp" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.korp.id
  }

  tags = { Name = "${var.prefixo}-rt" }
}

resource "aws_route_table_association" "korp" {
  subnet_id      = aws_subnet.korp.id
  route_table_id = aws_route_table.korp.id
}
