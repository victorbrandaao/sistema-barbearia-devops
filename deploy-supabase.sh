#!/bin/bash
# 🚀 Script de Deploy - Migração Supabase
# Execute após configurar o Supabase

set -e  # Para o script se houver erro

echo "🔄 Iniciando deploy com Supabase..."
echo ""

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar se terraform.tfvars existe
echo -e "${BLUE}📋 Passo 1: Verificando configuração Terraform...${NC}"
if [ ! -f "barbearia-infra/terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  Arquivo terraform.tfvars não encontrado!${NC}"
    echo "Crie o arquivo baseado em terraform.tfvars.example:"
    echo "  cd barbearia-infra"
    echo "  cp terraform.tfvars.example terraform.tfvars"
    echo "  # Edite terraform.tfvars com suas credenciais Supabase"
    exit 1
fi
echo -e "${GREEN}✅ Configuração encontrada${NC}"
echo ""

# 2. Aplicar Terraform (remover RDS se existir)
echo -e "${BLUE}🏗️  Passo 2: Atualizando infraestrutura AWS...${NC}"
cd barbearia-infra

# Aplicar nova configuração
echo "Aplicando configuração com Supabase..."
terraform init -upgrade
terraform apply -auto-approve

cd ..
echo -e "${GREEN}✅ Infraestrutura atualizada${NC}"
echo ""

# 3. Build da imagem Docker
echo -e "${BLUE}🐳 Passo 3: Construindo imagem Docker...${NC}"
docker build -t barbeariaapi-api:latest .
echo -e "${GREEN}✅ Imagem construída${NC}"
echo ""

# 4. Tag e Push para ECR
echo -e "${BLUE}📦 Passo 4: Enviando para ECR...${NC}"
docker tag barbeariaapi-api:latest \
    428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest

echo "Fazendo login no ECR..."
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    428014821600.dkr.ecr.us-east-1.amazonaws.com

echo "Enviando imagem..."
docker push 428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest
echo -e "${GREEN}✅ Imagem enviada${NC}"
echo ""

# 5. Force deploy no ECS
echo -e "${BLUE}🚀 Passo 5: Atualizando serviço ECS...${NC}"
aws ecs update-service \
    --cluster barbearia-cluster \
    --service barbearia-api-service \
    --force-new-deployment \
    --region us-east-1 \
    --no-cli-pager

echo -e "${GREEN}✅ Deploy iniciado${NC}"
echo ""

# 6. Aguardar deploy
echo -e "${BLUE}⏳ Aguardando deploy (isso pode levar ~2 minutos)...${NC}"
aws ecs wait services-stable \
    --cluster barbearia-cluster \
    --services barbearia-api-service \
    --region us-east-1

echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo ""

# 7. Testar API
echo -e "${BLUE}🧪 Testando API...${NC}"
sleep 5  # Aguardar alguns segundos

echo "Testando endpoint /api/barbeiros..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://app.victorbrandao.tech/api/barbeiros)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ API respondendo corretamente (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${YELLOW}⚠️  API retornou HTTP $HTTP_CODE${NC}"
    echo "Verifique os logs: aws logs tail /ecs/barbearia-api --follow --region us-east-1"
fi
echo ""

# 8. Resumo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📍 Acessos:"
echo "   API: https://app.victorbrandao.tech"
echo "   Cliente: https://app.victorbrandao.tech/index.html"
echo "   Admin: https://app.victorbrandao.tech/admin.html"
echo ""
echo "📊 Monitoramento:"
echo "   Logs ECS: aws logs tail /ecs/barbearia-api --follow --region us-east-1"
echo "   Supabase: https://supabase.com/dashboard/project/_/logs/explorer"
echo ""
echo "💰 Economia com Supabase:"
echo "   RDS: ~$17/mês → Supabase Free: $0/mês"
echo "   Economia anual: ~$204/ano 🎉"
echo ""
