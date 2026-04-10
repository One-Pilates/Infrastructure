# ============================================================
# EC2 Instances - OnePilates
# ============================================================

# -----------------------------------------------
# proxy-01 - Nginx Reverse Proxy (Sub-rede Pública)
# -----------------------------------------------
resource "aws_instance" "proxy_01" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_proxy
  subnet_id              = aws_subnet.publica.id
  vpc_security_group_ids = [aws_security_group.proxy.id]
  key_name               = var.key_name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=========================================="
    echo " PROXY-01 - Nginx Reverse Proxy Setup"
    echo "=========================================="

    # Atualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Instalar Nginx
    apt-get install -y nginx

    # Configuração do Nginx como Reverse Proxy
    cat > /etc/nginx/sites-available/default <<'NGINX'
    upstream landingpage {
        server ${aws_instance.landingpage_01.private_ip}:5173;
    }

    upstream frontend {
        server ${aws_instance.webserver_01.private_ip}:5173;
    }

    upstream backend {
        server ${aws_instance.appserver_01.private_ip}:8080;
    }

    server {
        listen 80;
        server_name _;

        # Landing Page (rota padrão)
        location / {
            proxy_pass http://landingpage;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # Aplicação Web (Frontend - Sistema de Gestão)
        location /app/ {
            proxy_pass http://frontend/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # API Backend (Spring Boot)
        location /api/ {
            proxy_pass http://backend/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    NGINX

    # Testar e reiniciar Nginx
    nginx -t
    systemctl restart nginx
    systemctl enable nginx

    echo "=========================================="
    echo " PROXY-01 - Setup Completo!"
    echo "=========================================="
  EOF

  tags = {
    Name    = "${var.projeto}-proxy-01"
    Role    = "nginx-reverse-proxy"
    Projeto = var.projeto
  }

  depends_on = [
    aws_instance.landingpage_01,
    aws_instance.webserver_01,
    aws_instance.appserver_01
  ]
}

# Elastic IP para o proxy-01
resource "aws_eip" "proxy_eip" {
  instance = aws_instance.proxy_01.id
  domain   = "vpc"

  tags = {
    Name    = "${var.projeto}-proxy-eip"
    Projeto = var.projeto
  }

  depends_on = [aws_internet_gateway.igw]
}

# -----------------------------------------------
# landingpage-01 - Landing Page (React 18 + Vite + TypeScript)
# Repo: https://github.com/One-Pilates/LandingPage
# Stack: Vite, React 18, TypeScript, Tailwind CSS, Framer Motion
# -----------------------------------------------
resource "aws_instance" "landingpage_01" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_app
  subnet_id              = aws_subnet.privada_app.id
  vpc_security_group_ids = [aws_security_group.landingpage.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=========================================="
    echo " LANDINGPAGE-01 - Landing Page Setup"
    echo " Repo: One-Pilates/LandingPage"
    echo "=========================================="

    # Atualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Instalar dependências
    apt-get install -y curl git

    # Instalar Node.js 18 LTS via NodeSource
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    # Verificar instalação
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"

    # Criar diretório do projeto
    mkdir -p /opt/onepilates
    cd /opt/onepilates

    # Clonar o repositório da Landing Page
    git clone https://github.com/One-Pilates/LandingPage.git
    cd LandingPage

    # Instalar dependências do projeto
    npm install

    # Criar serviço systemd para a Landing Page
    cat > /etc/systemd/system/landingpage.service <<'SERVICE'
    [Unit]
    Description=OnePilates Landing Page (Vite Dev Server)
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/onepilates/LandingPage
    ExecStart=/usr/bin/npm run dev -- --host 0.0.0.0
    Restart=on-failure
    RestartSec=10
    Environment=NODE_ENV=production

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Habilitar e iniciar o serviço
    systemctl daemon-reload
    systemctl enable landingpage.service
    systemctl start landingpage.service

    echo "=========================================="
    echo " LANDINGPAGE-01 - Setup Completo!"
    echo " App rodando em: http://0.0.0.0:5173"
    echo "=========================================="
  EOF

  tags = {
    Name    = "${var.projeto}-landingpage-01"
    Role    = "landing-page"
    App     = "frontend-01-react-vite-typescript"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# web-server-01 - Frontend Sistema de Gestão (React 19 + Vite)
# Repo: https://github.com/One-Pilates/Frontend
# Stack: Vite, React 19, Tailwind, SCSS, FullCalendar, HighCharts
# -----------------------------------------------
resource "aws_instance" "webserver_01" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_app
  subnet_id              = aws_subnet.privada_app.id
  vpc_security_group_ids = [aws_security_group.webserver.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=========================================="
    echo " WEB-SERVER-01 - Frontend App Setup"
    echo " Repo: One-Pilates/Frontend"
    echo "=========================================="

    # Atualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Instalar dependências
    apt-get install -y curl git

    # Instalar Node.js 18 LTS via NodeSource
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    # Verificar instalação
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"

    # Criar diretório do projeto
    mkdir -p /opt/onepilates
    cd /opt/onepilates

    # Clonar o repositório do Frontend
    git clone https://github.com/One-Pilates/Frontend.git
    cd Frontend

    # Instalar dependências do projeto
    npm install

    # Criar serviço systemd para o Frontend
    cat > /etc/systemd/system/frontend.service <<'SERVICE'
    [Unit]
    Description=OnePilates Frontend App (Vite Dev Server)
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/onepilates/Frontend
    ExecStart=/usr/bin/npm run dev -- --host 0.0.0.0
    Restart=on-failure
    RestartSec=10
    Environment=NODE_ENV=production

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Habilitar e iniciar o serviço
    systemctl daemon-reload
    systemctl enable frontend.service
    systemctl start frontend.service

    echo "=========================================="
    echo " WEB-SERVER-01 - Setup Completo!"
    echo " App rodando em: http://0.0.0.0:5173"
    echo "=========================================="
  EOF

  tags = {
    Name    = "${var.projeto}-web-server-01"
    Role    = "web-server"
    App     = "frontend-02-react-vite-scss"
    Projeto = var.projeto
  }
}

# -----------------------------------------------
# app-server-01 - Backend (Java 17 + Spring Boot 3 + RabbitMQ)
# Repo: https://github.com/One-Pilates/Backend (branch: development)
# Stack: Java 17, Spring Boot 3, Maven, Spring Security JWT, RabbitMQ
# -----------------------------------------------
resource "aws_instance" "appserver_01" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_app
  subnet_id              = aws_subnet.privada_app.id
  vpc_security_group_ids = [aws_security_group.appserver.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=========================================="
    echo " APP-SERVER-01 - Backend Setup"
    echo " Repo: One-Pilates/Backend"
    echo "=========================================="

    # Atualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Instalar dependências
    apt-get install -y curl git docker.io docker-compose

    # Instalar Java 17 (OpenJDK)
    apt-get install -y openjdk-17-jdk

    # Instalar Maven
    apt-get install -y maven

    # Verificar instalações
    echo "Java version: $(java -version 2>&1)"
    echo "Maven version: $(mvn -version 2>&1 | head -1)"

    # Iniciar Docker (para RabbitMQ)
    systemctl start docker
    systemctl enable docker

    # Iniciar RabbitMQ via Docker
    docker run -d \
      --name rabbitmq \
      --restart always \
      -p 5672:5672 \
      -p 15672:15672 \
      -e RABBITMQ_DEFAULT_USER=guest \
      -e RABBITMQ_DEFAULT_PASS=guest \
      rabbitmq:3.12-management

    echo "Aguardando RabbitMQ iniciar..."
    sleep 15

    # Criar diretório do projeto
    mkdir -p /opt/onepilates
    cd /opt/onepilates

    # Clonar o repositório do Backend (branch development)
    git clone -b development https://github.com/One-Pilates/Backend.git
    cd Backend/agendamento

    # Configurar application.properties para apontar ao MySQL interno
    mkdir -p src/main/resources
    cat > src/main/resources/application.properties <<'PROPS'
    # Database - MySQL na instância database-01
    spring.datasource.url=jdbc:mysql://${aws_instance.database_01.private_ip}:3306/onepilates
    spring.datasource.username=root
    spring.datasource.password=onepilates2024
    spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

    # JPA
    spring.jpa.hibernate.ddl-auto=update
    spring.jpa.show-sql=true
    spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect

    # JWT
    jwt.secret=onepilates-secret-key-2024
    jwt.expiration=86400000

    # RabbitMQ
    spring.rabbitmq.host=localhost
    spring.rabbitmq.port=5672
    spring.rabbitmq.username=guest
    spring.rabbitmq.password=guest

    # Server
    server.port=8080

    # S3
    aws.s3.bucket=${aws_s3_bucket.image_bucket.bucket}
    aws.s3.region=${var.aws_region}
    PROPS

    # Build do projeto (skip tests para deploy mais rápido)
    mvn clean package -DskipTests

    # Criar serviço systemd para o Backend
    cat > /etc/systemd/system/backend.service <<'SERVICE'
    [Unit]
    Description=OnePilates Backend (Spring Boot)
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/onepilates/Backend/agendamento
    ExecStart=/usr/bin/java -jar target/agendamento-0.0.1-SNAPSHOT.jar
    Restart=on-failure
    RestartSec=10
    Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Habilitar e iniciar o serviço
    systemctl daemon-reload
    systemctl enable backend.service
    systemctl start backend.service

    echo "=========================================="
    echo " APP-SERVER-01 - Setup Completo!"
    echo " API rodando em: http://0.0.0.0:8080"
    echo " Swagger: http://0.0.0.0:8080/swagger-ui.html"
    echo " RabbitMQ UI: http://0.0.0.0:15672"
    echo "=========================================="
  EOF

  tags = {
    Name    = "${var.projeto}-app-server-01"
    Role    = "app-server"
    App     = "backend-springboot-rabbitmq"
    Projeto = var.projeto
  }

  depends_on = [
    aws_instance.database_01
  ]
}

# -----------------------------------------------
# database-01 - MySQL Server (Docker)
# -----------------------------------------------
resource "aws_instance" "database_01" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.privada_app.id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name               = var.key_name

  # Volume adicional para dados do MySQL
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=========================================="
    echo " DATABASE-01 - MySQL Server Setup"
    echo "=========================================="

    # Atualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Instalar Docker e Git
    apt-get install -y docker.io docker-compose git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # Criar volume para persistência
    mkdir -p /data/mysql

    # Iniciar MySQL 8.0 via Docker
    docker run -d \
      --name mysql-01 \
      --restart always \
      -e MYSQL_ROOT_PASSWORD=onepilates2024 \
      -e MYSQL_DATABASE=onepilates \
      -e MYSQL_CHARACTER_SET_SERVER=utf8mb4 \
      -e MYSQL_COLLATION_SERVER=utf8mb4_unicode_ci \
      -p 3306:3306 \
      -v /data/mysql:/var/lib/mysql \
      mysql:8.0

    # ==========================================
    # DADOS INICIAIS - Clonar e executar SQL
    # ==========================================
    echo "Clonando repositório Database..."
    mkdir -p /opt/onepilates
    git clone https://github.com/One-Pilates/Database.git /opt/onepilates/Database

    # Aguardar MySQL ficar pronto (health check com retry)
    echo "Aguardando MySQL ficar pronto..."
    for i in $(seq 1 30); do
      if docker exec mysql-01 mysqladmin ping -h localhost -u root -ponepilates2024 2>/dev/null; then
        echo "MySQL está pronto! (tentativa $i)"
        break
      fi
      echo "Tentativa $i/30 - Aguardando..."
      sleep 5
    done

    # Aguardar mais um pouco para o MySQL aceitar conexões SQL
    sleep 10

    # Executar dados iniciais
    echo "Inserindo dados iniciais no banco..."
    docker exec -i mysql-01 mysql -u root -ponepilates2024 onepilates < /opt/onepilates/Database/dados_iniciais.sql

    if [ $? -eq 0 ]; then
      echo "=========================================="
      echo " DADOS INICIAIS INSERIDOS COM SUCESSO!"
      echo "=========================================="
    else
      echo "AVISO: Erro ao inserir dados iniciais. Verifique /var/log/user-data.log"
    fi

    echo "=========================================="
    echo " DATABASE-01 - Setup Completo!"
    echo " MySQL rodando em: 0.0.0.0:3306"
    echo " Database: onepilates"
    echo " Dados iniciais: INSERIDOS"
    echo "=========================================="
  EOF

  tags = {
    Name    = "${var.projeto}-database-01"
    Role    = "database"
    App     = "mysql-01"
    Projeto = var.projeto
  }
}