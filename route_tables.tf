# ============================================================
# Tabelas de Rotas - OnePilates
# ============================================================

# -----------------------------------------------
# Tabela de Rotas Pública → Internet Gateway
# Rota: 0.0.0.0/0 → IGW
# -----------------------------------------------
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.projeto}-rt-publica"
    Projeto = var.projeto
  }
}

resource "aws_route_table_association" "publica" {
  subnet_id      = aws_subnet.publica.id
  route_table_id = aws_route_table.publica.id
}

# -----------------------------------------------
# Tabela de Rotas Privada → NAT Gateway
# Rota: 0.0.0.0/0 → NAT
# -----------------------------------------------
resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name    = "${var.projeto}-rt-privada"
    Projeto = var.projeto
  }
}

resource "aws_route_table_association" "privada_app" {
  subnet_id      = aws_subnet.privada_app.id
  route_table_id = aws_route_table.privada.id
}