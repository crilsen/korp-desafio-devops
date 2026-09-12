# Instância EC2
resource "aws_instance" "korp" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.korp.id
  vpc_security_group_ids = [aws_security_group.korp.id]
  key_name               = aws_key_pair.korp.key_name

  # no primeiro boot, instala e registra o runner self-hosted
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    github_repo    = var.github_repo
    github_pat     = var.github_pat
    runner_name    = var.runner_name
    runner_version = var.runner_version
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "${var.prefixo}-ec2" }
}

# EIP já existente, reaproveitando (IP definido em terraform.tfvars)
data "aws_eip" "korp" {
  public_ip = var.eip_public_ip
}

resource "aws_eip_association" "korp" {
  instance_id   = aws_instance.korp.id
  allocation_id = data.aws_eip.korp.id
}
