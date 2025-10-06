# 🏆 Barbearia Imperial

Sistema completo de agendamento para barbearias com painel administrativo.

## 🚀 Tecnologias

**Backend:**

- .NET 9 / ASP.NET Core
- Entity Framework Core
- PostgreSQL
- JWT Authentication

**Frontend:**

- HTML5 + CSS3 + JavaScript
- TailwindCSS
- Chart.js

**DevOps:**

- Docker + Docker Compose
- AWS ECS Fargate
- AWS RDS PostgreSQL
- Terraform

## 📦 Instalação Local

```bash
# Clone o repositório
git clone https://github.com/victorbrandaao/sistema-barbearia-devops.git
cd sistema-barbearia-devops

# Suba os containers
docker-compose up -d

# A API estará disponível em http://localhost:8080
```

## 🌐 Produção

**URL:** https://api.victorbrandao.tech

**Painel Admin:** https://api.victorbrandao.tech/admin.html

- Usuário: `admin`
- Senha: `password123`

## 📚 Endpoints da API

### Agendamentos

- `GET /api/agendamentos` - Lista agendamentos (filtros: status, barbeiro, dataInicio, dataFim)
- `POST /api/agendamentos` - Criar agendamento
- `GET /api/agendamentos/estatisticas` - Estatísticas [Auth]
- `PUT /api/agendamentos/{id}/concluir` - Marcar como concluído [Auth]
- `PUT /api/agendamentos/{id}/cancelar` - Cancelar [Auth]
- `DELETE /api/agendamentos/{id}` - Excluir [Auth]

### Barbeiros

- `GET /api/barbeiros` - Listar barbeiros
- `POST /api/barbeiros` - Adicionar barbeiro [Auth]
- `DELETE /api/barbeiros/{id}` - Remover barbeiro [Auth]

### Horários

- `GET /api/horarios/disponiveis?data={YYYY-MM-DD}` - Horários disponíveis

### Autenticação

- `POST /api/auth/login` - Login (retorna JWT token)

## 🔐 Segurança

- Autenticação JWT
- HTTPS obrigatório (produção)
- CORS configurado
- Validação de entrada
- Secrets em variáveis de ambiente

## 🛠️ Deploy

```bash
# Build da imagem
docker build -t barbeariaapi-api:latest .

# Tag para ECR
docker tag barbeariaapi-api:latest 428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest

# Login no ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 428014821600.dkr.ecr.us-east-1.amazonaws.com

# Push
docker push 428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest

# Deploy no ECS
aws ecs update-service --cluster barbearia-cluster --service barbearia-api-service --force-new-deployment --region us-east-1
```

## 📝 Licença

Projeto proprietário - Barbearia Imperial © 2025
