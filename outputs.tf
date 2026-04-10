# ============================================================
# Outputs - OnePilates AWS Infrastructure
# ============================================================

# --- VPC ---
output "vpc_id" {
  description = "ID da VPC principal"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR Block da VPC"
  value       = aws_vpc.main.cidr_block
}

# --- Subnets ---
output "subnet_publica_id" {
  description = "ID da Sub-rede Pública"
  value       = aws_subnet.publica.id
}

output "subnet_privada_app_id" {
  description = "ID da Sub-rede Privada de Aplicação"
  value       = aws_subnet.privada_app.id
}

# --- Gateways ---
output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway"
  value       = aws_nat_gateway.nat.id
}

# --- EC2 Instances ---
output "proxy_01_public_ip" {
  description = "IP Público do proxy-01 (Nginx Reverse Proxy)"
  value       = aws_eip.proxy_eip.public_ip
}

output "proxy_01_private_ip" {
  description = "IP Privado do proxy-01"
  value       = aws_instance.proxy_01.private_ip
}

output "landingpage_01_private_ip" {
  description = "IP Privado do landingpage-01"
  value       = aws_instance.landingpage_01.private_ip
}

output "webserver_01_private_ip" {
  description = "IP Privado do web-server-01"
  value       = aws_instance.webserver_01.private_ip
}

output "appserver_01_private_ip" {
  description = "IP Privado do app-server-01"
  value       = aws_instance.appserver_01.private_ip
}

output "database_01_private_ip" {
  description = "IP Privado do database-01 (MySQL)"
  value       = aws_instance.database_01.private_ip
}

# --- S3 ---
output "s3_image_bucket_name" {
  description = "Nome do S3 Bucket de imagens"
  value       = aws_s3_bucket.image_bucket.bucket
}

output "s3_image_bucket_arn" {
  description = "ARN do S3 Bucket de imagens"
  value       = aws_s3_bucket.image_bucket.arn
}
