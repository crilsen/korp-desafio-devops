output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.korp.id
}

output "public_ip" {
  description = "IP público (elástico) da instância"
  value       = data.aws_eip.korp.public_ip
}

output "private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.korp.private_ip
}

output "key_name" {
  description = "Nome do par de chaves"
  value       = aws_key_pair.korp.key_name
}

output "pem_local" {
  description = "Caminho local da chave privada gerada"
  value       = local_file.korp_pem.filename
}

output "vpc_id" {
  value = aws_vpc.korp.id
}

output "subnet_id" {
  value = aws_subnet.korp.id
}

output "security_group_id" {
  value = aws_security_group.korp.id
}

output "route_table_id" {
  value = aws_route_table.korp.id
}

output "ssh_comando" {
  description = "Como conectar na instância depois do deploy"
  value       = "ssh -i ${local_file.korp_pem.filename} ubuntu@${data.aws_eip.korp.public_ip}"
}
