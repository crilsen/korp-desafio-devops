# Instância EC2
resource "aws_instance" "korp" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.korp.id
  vpc_security_group_ids = [aws_security_group.korp.id]
  key_name               = data.aws_key_pair.korp.key_name
  iam_instance_profile   = aws_iam_instance_profile.korp_runner.name

  # no primeiro boot, instala e registra o runner self-hosted
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    github_repo                        = var.github_repo
    github_runner_token_parameter_name = var.github_runner_token_parameter_name
    runner_name                        = var.runner_name
    runner_version                     = var.runner_version
    bootstrap_runner_script            = file("${path.module}/../scripts/bootstrap-runner.sh")
  })
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
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
