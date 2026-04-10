# ============================================================
# Internet Gateway + NAT Gateway - OnePilates
# ============================================================

# Internet Gateway - acesso da sub-rede pública à Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.projeto}-igw"
    Projeto = var.projeto
  }
}

# Elastic IP para o NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name    = "${var.projeto}-nat-eip"
    Projeto = var.projeto
  }

  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway - permite que a sub-rede privada acesse a Internet
# Posicionado na sub-rede pública conforme a arquitetura
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.publica.id

  tags = {
    Name    = "${var.projeto}-nat-gateway"
    Projeto = var.projeto
  }

  depends_on = [aws_internet_gateway.igw]
}