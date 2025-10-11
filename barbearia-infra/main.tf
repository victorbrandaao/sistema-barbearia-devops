# Define o provedor de nuvem (AWS) e a região.
provider "aws" {
  region = "us-east-1"
}

# --- Variáveis para Senhas e Nomes ---
variable "db_user" {
  description = "Utilizador do banco de dados RDS"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados RDS que será passada via linha de comando"
  type        = string
  sensitive   = true
}

variable "supabase_connection_string" {
  description = "String de conexão do Supabase"
  type        = string
  sensitive   = true
}

variable "api_domain_name" {
  description = "O subdomínio completo para a API"
  type        = string
  default     = "api.victorbrandao.tech"
}


# --- Rede (VPC) e Segurança ---
resource "aws_vpc" "barbearia_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "barbearia-vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.barbearia_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "barbearia-public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.barbearia_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "barbearia-public-subnet-b"
  }
}

resource "aws_internet_gateway" "barbearia_igw" {
  vpc_id = aws_vpc.barbearia_vpc.id
  tags = {
    Name = "barbearia-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.barbearia_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.barbearia_igw.id
  }
  tags = {
    Name = "barbearia-public-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group para o Load Balancer (permite tráfego HTTPS da internet)
resource "aws_security_group" "alb_sg" {
  name        = "barbearia-alb-sg"
  description = "Permite trafego HTTPS para o ALB"
  vpc_id      = aws_vpc.barbearia_vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para o serviço ECS (permite tráfego APENAS do Load Balancer)
resource "aws_security_group" "ecs_sg" {
  name        = "barbearia-ecs-sg"
  description = "Permite trafego do ALB para o servico ECS"
  vpc_id      = aws_vpc.barbearia_vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Repositório da Imagem (ECR) ---
resource "aws_ecr_repository" "barbearia_api_repo" {
  name                 = "barbearia-api-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- Certificado SSL (ACM) ---
resource "aws_acm_certificate" "cert" {
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}

# --- Load Balancer (ALB) ---
resource "aws_lb" "barbearia_alb" {
  name               = "barbearia-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_lb_target_group" "barbearia_tg" {
  name        = "barbearia-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.barbearia_vpc.id
  target_type = "ip"

  health_check {
    path                = "/api/barbeiros"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.barbearia_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.barbearia_tg.arn
  }
}

# --- Contentores (ECS) ---
resource "aws_ecs_cluster" "barbearia_cluster" {
  name = "barbearia-cluster"
}

resource "aws_ecs_task_definition" "barbearia_task" {
  family                   = "barbearia-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "barbearia-api-container",
      image     = "${aws_ecr_repository.barbearia_api_repo.repository_url}:latest",
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        { containerPort = 80, hostPort = 80 }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.barbearia_logs.name,
          "awslogs-region"        = "us-east-1",
          "awslogs-stream-prefix" = "ecs"
        }
      },
      environment = [
        { name = "ASPNETCORE_URLS", value = "http://+:80" },
        { name = "ConnectionStrings__DefaultConnection", value = var.supabase_connection_string },
        { name = "Jwt__Key", value = "uma_chave_secreta_muito_longa_e_dificil_de_adivinhar_para_usar_em_producao_123!" },
        { name = "Admin__User", value = "admin" },
        { name = "Admin__Password", value = "password123" }
      ]
    }
  ])
}

resource "aws_ecs_service" "barbearia_service" {
  name            = "barbearia-api-service"
  cluster         = aws_ecs_cluster.barbearia_cluster.id
  task_definition = aws_ecs_task_definition.barbearia_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.barbearia_tg.arn
    container_name   = "barbearia-api-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.https]
}

# --- Logging e Permissões ---
resource "aws_cloudwatch_log_group" "barbearia_logs" {
  name = "/ecs/barbearia-api"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Saídas (Outputs) ---
output "certificate_arn" {
  description = "ARN do certificado ACM criado"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_validation_cname_name" {
  description = "O NOME do registo CNAME que precisa de criar na Hostinger para validar o certificado"
  value       = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
}

output "certificate_validation_cname_value" {
  description = "O VALOR do registo CNAME que precisa de criar na Hostinger para validar o certificado"
  value       = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value
}

output "load_balancer_dns_name" {
  description = "O nome DNS do Load Balancer para usar no seu registo CNAME"
  value       = aws_lb.barbearia_alb.dns_name
}
