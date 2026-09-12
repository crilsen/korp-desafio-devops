# Route table e associação com a subnet
resource "aws_route_table" "korp" {
  vpc_id = aws_vpc.korp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.korp.id
  }

  tags = { Name = "${var.prefixo}-rt" }
}

resource "aws_route_table_association" "korp" {
  subnet_id      = aws_subnet.korp.id
  route_table_id = aws_route_table.korp.id
}
