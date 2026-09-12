# VPC e gateway de internet
resource "aws_vpc" "korp" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.prefixo}-vpc" }
}

resource "aws_internet_gateway" "korp" {
  vpc_id = aws_vpc.korp.id

  tags = { Name = "${var.prefixo}-igw" }
}
