# ============================================================
# Security Groups - OnePilates
# ============================================================

# -----------------------------------------------
# SG: proxy-01 (Nginx Reverse Proxy) - Sub-rede Pública
# -----------------------------------------------
resource "aws_security_group" "proxy" {
  name        = "${var.projeto}-sg-proxy"
  description = "Security Group para o Nginx Reverse Proxy (proxy-01)"
  vpc_id      = aws_vpc.main.id

  # HTTP da Internet
  ingress {
    description = "HTTP da Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS da Internet
  ingress {
    description = "HTTPS da Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH para administração
  ingress {
    description = "SSH para administracao"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.meu_ip]
  }

  # Saída total
  egress {
    description = "Saida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.projeto}-sg-proxy"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# SG: landingpage-01 (Landing Page - React Vite.js)
# -----------------------------------------------
resource "aws_security_group" "landingpage" {
  name        = "${var.projeto}-sg-landingpage"
  description = "Security Group para Landing Page (landingpage-01)"
  vpc_id      = aws_vpc.main.id

  # HTTP vindo do proxy
  ingress {
    description     = "HTTP do proxy"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Vite Dev Server (porta 5173) do proxy
  ingress {
    description     = "Vite Dev Server do proxy"
    from_port       = 5173
    to_port         = 5173
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # SSH do proxy (bastion)
  ingress {
    description     = "SSH via proxy (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Saída total
  egress {
    description = "Saida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.projeto}-sg-landingpage"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# SG: web-server-01 (Frontend React + Nginx + Load Balancer)
# -----------------------------------------------
resource "aws_security_group" "webserver" {
  name        = "${var.projeto}-sg-webserver"
  description = "Security Group para o Web Server (web-server-01)"
  vpc_id      = aws_vpc.main.id

  # HTTP vindo do proxy
  ingress {
    description     = "HTTP do proxy"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Vite Dev Server (porta 5173) do proxy
  ingress {
    description     = "Vite Dev Server do proxy"
    from_port       = 5173
    to_port         = 5173
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # SSH do proxy (bastion)
  ingress {
    description     = "SSH via proxy (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Saída total
  egress {
    description = "Saida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.projeto}-sg-webserver"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# SG: app-server-01 (Core Pilates - Backend Java Spring Boot + RabbitMQ)
# -----------------------------------------------
resource "aws_security_group" "appserver" {
  name        = "${var.projeto}-sg-appserver"
  description = "Security Group para App Server (app-server-01) - Backend APIs + RabbitMQ"
  vpc_id      = aws_vpc.main.id

  # API porta 8080 - do web-server (frontend)
  ingress {
    description     = "API 8080 do web-server"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver.id]
  }

  # API porta 8080 - do proxy (direto)
  ingress {
    description     = "API 8080 do proxy"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # RabbitMQ AMQP (porta 5672) - comunicação interna entre micro-serviços
  ingress {
    description = "RabbitMQ AMQP - comunicacao interna"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    self        = true
  }

  # RabbitMQ Management (porta 15672)
  ingress {
    description = "RabbitMQ Management"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    self        = true
  }

  # SSH do proxy (bastion)
  ingress {
    description     = "SSH via proxy (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Saída total
  egress {
    description = "Saida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.projeto}-sg-appserver"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# SG: database-01 (MySQL Server)
# -----------------------------------------------
resource "aws_security_group" "database" {
  name        = "${var.projeto}-sg-database"
  description = "Security Group para o Database (database-01) - MySQL"
  vpc_id      = aws_vpc.main.id

  # MySQL porta 3306 - do app-server (backend)
  ingress {
    description     = "MySQL 3306 do app-server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  # SSH do proxy (bastion)
  ingress {
    description     = "SSH via proxy (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Saída total
  egress {
    description = "Saida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.projeto}-sg-database"
    Projeto = var.projeto
  }
}