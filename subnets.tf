# ============================================================
# Subnets - OnePilates
# ============================================================

# Sub-rede Pública - 10.0.1.0/24
# Contém: proxy-01 (Nginx Reverse Proxy)
resource "aws_subnet" "publica" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.projeto}-sub-rede-publica"
    Tipo    = "publica"
    Projeto = var.projeto
  }
}

# Sub-rede Aplicação Privada - 10.0.2.0/24
# Contém: landingpage-01, web-server-01, app-server-01, database-01
resource "aws_subnet" "privada_app" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name    = "${var.projeto}-sub-rede-privada-app"
    Tipo    = "privada"
    Projeto = var.projeto
  }
}