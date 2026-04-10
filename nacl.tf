# ============================================================
# Network ACLs (NACLs) - OnePilates
# ============================================================

# -----------------------------------------------
# NACL Pública
# - Permitir HTTP 80
# - Permitir SSH 22
# -----------------------------------------------
resource "aws_network_acl" "publica" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.publica.id]

  # --- Regras de Entrada (Ingress) ---

  # Permitir HTTP (porta 80)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Permitir HTTPS (porta 443)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Permitir SSH (porta 22)
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Permitir portas efêmeras (retorno de tráfego)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # --- Regras de Saída (Egress) ---

  # Permitir todo tráfego de saída
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name    = "${var.projeto}-nacl-publica"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# NACL Privada App
# - Permitir porta 8080 (API Spring Boot)
# - Permitir porta 3306 (MySQL)
# -----------------------------------------------
resource "aws_network_acl" "privada_app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.privada_app.id]

  # --- Regras de Entrada (Ingress) ---

  # Permitir HTTP do proxy (porta 80) - landing page e frontend
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 80
    to_port    = 80
  }

  # Permitir API (porta 8080) - da sub-rede pública
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 8080
    to_port    = 8080
  }

  # Permitir MySQL (porta 3306) - comunicação interna
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.0.2.0/24"
    from_port  = 3306
    to_port    = 3306
  }

  # Permitir API secundária (porta 19972) - RabbitMQ / micro-serviço
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "10.0.2.0/24"
    from_port  = 5672
    to_port    = 5672
  }

  # Permitir RabbitMQ Management (porta 15672)
  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "10.0.2.0/24"
    from_port  = 15672
    to_port    = 15672
  }

  # Permitir SSH interno (porta 22) - administração
  ingress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 22
    to_port    = 22
  }

  # Permitir portas efêmeras (retorno de tráfego NAT)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # --- Regras de Saída (Egress) ---

  # Permitir todo tráfego de saída (necessário para NAT Gateway)
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name    = "${var.projeto}-nacl-privada-app"
    Projeto = var.projeto
  }
}
