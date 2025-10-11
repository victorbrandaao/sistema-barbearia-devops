# 🔄 Migração para Supabase

## 📋 Checklist de Migração

- [ ] Criar projeto no Supabase
- [ ] Obter connection string do Supabase
- [ ] Criar tabelas no Supabase
- [ ] Atualizar appsettings.json
- [ ] Atualizar Terraform (remover RDS)
- [ ] Rebuild da imagem Docker
- [ ] Deploy no ECS
- [ ] Testar aplicação

---

## 🚀 Passo 1: Criar Projeto no Supabase

1. Acesse: https://supabase.com
2. Clique em **"New Project"**
3. Preencha:
   - **Name**: `barbearia-imperial`
   - **Database Password**: [escolha uma senha forte]
   - **Region**: `East US (North Virginia)` (mesma do ECS)
   - **Pricing Plan**: Free (ou Pro se necessário)
4. Aguarde ~2 minutos para provisionar

---

## 🔑 Passo 2: Obter Credenciais

No dashboard do projeto Supabase:

1. Vá em **Settings** → **Database**
2. Role até **Connection String** → **Connection Pooling**
3. Selecione **Session mode** (para Entity Framework)
4. Copie a connection string:

```
postgresql://postgres.xxxxxxxxxxxxx:[SUA-SENHA]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

⚠️ **Importante**: Use a porta `6543` (connection pooling) em vez de `5432`

---

## 🗄️ Passo 3: Criar Schema no Supabase

### Opção A: Via SQL Editor (Recomendado)

No Supabase Dashboard → **SQL Editor** → **New Query**:

```sql
-- Criar tabela Barbeiros
CREATE TABLE IF NOT EXISTS "Barbeiros" (
    "Id" SERIAL PRIMARY KEY,
    "Nome" VARCHAR(100) NOT NULL,
    "Especialidade" VARCHAR(200)
);

-- Criar tabela Agendamentos
CREATE TABLE IF NOT EXISTS "Agendamentos" (
    "Id" SERIAL PRIMARY KEY,
    "NomeCliente" VARCHAR(100) NOT NULL,
    "Telefone" VARCHAR(20) NOT NULL,
    "NomeBarbeiro" VARCHAR(100) NOT NULL,
    "Servico" VARCHAR(100) NOT NULL,
    "DataHora" TIMESTAMP NOT NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Agendado'
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON "Agendamentos"("DataHora");
CREATE INDEX IF NOT EXISTS idx_agendamentos_status ON "Agendamentos"("Status");
CREATE INDEX IF NOT EXISTS idx_agendamentos_barbeiro ON "Agendamentos"("NomeBarbeiro");

-- Inserir barbeiros iniciais
INSERT INTO "Barbeiros" ("Nome", "Especialidade") VALUES
('João Silva', 'Cortes modernos e barbas'),
('Pedro Santos', 'Especialista em degradê'),
('Carlos Lima', 'Barbas e finalização')
ON CONFLICT DO NOTHING;

-- Verificar se as tabelas foram criadas
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

### Opção B: Via Entity Framework (Local)

```bash
# No seu terminal local
export ConnectionStrings__DefaultConnection="postgresql://postgres.xxxxx:[SENHA]@aws-0-us-east-1.pooler.supabase.com:6543/postgres"

dotnet ef database update
```

---

## ⚙️ Passo 4: Atualizar appsettings.json

O arquivo `appsettings.json` já foi atualizado automaticamente.

**Variáveis de Ambiente no ECS** (será atualizado no Terraform):

```bash
ConnectionStrings__DefaultConnection=postgresql://postgres.xxxxx:[SENHA]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

---

## 🏗️ Passo 5: Atualizar Terraform

O arquivo `barbearia-infra/main.tf` foi atualizado:

**Removido:**

- ❌ `aws_db_instance.barbearia_db` (RDS)
- ❌ `aws_db_subnet_group.db_subnet_group`
- ❌ `aws_security_group.db_sg`
- ❌ Variável `db_user`
- ❌ Variável `db_password`

**Adicionado:**

- ✅ Variável `supabase_connection_string`
- ✅ Connection string do Supabase no ECS task

---

## 🐳 Passo 6: Deploy

### 6.1 Criar arquivo de variáveis do Terraform

Crie `barbearia-infra/terraform.tfvars`:

```hcl
supabase_connection_string = "postgresql://postgres.xxxxx:[SENHA]@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
api_domain_name            = "api.victorbrandao.tech"
```

⚠️ **Não commite este arquivo!** (já está no .gitignore)

### 6.2 Aplicar Terraform

```bash
cd barbearia-infra

# Destruir recursos RDS
terraform destroy -target=aws_db_instance.barbearia_db
terraform destroy -target=aws_db_subnet_group.db_subnet_group
terraform destroy -target=aws_security_group.db_sg

# Aplicar nova configuração
terraform apply
```

### 6.3 Rebuild e Push da Imagem Docker

```bash
cd ..

# Build
docker build -t barbeariaapi-api:latest .

# Tag
docker tag barbeariaapi-api:latest \
  428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest

# Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  428014821600.dkr.ecr.us-east-1.amazonaws.com

# Push
docker push 428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest
```

### 6.4 Force Deploy no ECS

```bash
aws ecs update-service \
  --cluster barbearia-cluster \
  --service barbearia-api-service \
  --force-new-deployment \
  --region us-east-1
```

---

## ✅ Passo 7: Verificar

### 7.1 Logs do ECS

```bash
aws logs tail /ecs/barbearia-api --follow --region us-east-1
```

Procure por:

```
✅ Application started successfully
✅ Now listening on: http://+:80
```

### 7.2 Testar API

```bash
# Listar barbeiros
curl https://api.victorbrandao.tech/api/barbeiros

# Listar agendamentos
curl https://api.victorbrandao.tech/api/agendamentos

# Health check
curl https://api.victorbrandao.tech/api/barbeiros -I
```

### 7.3 Testar Frontend

Acesse:

- **Cliente**: https://api.victorbrandao.tech/index.html
- **Admin**: https://api.victorbrandao.tech/admin.html

---

## 💰 Economia de Custos

### Antes (AWS RDS):

- **RDS db.t3.micro**: ~$15/mês
- **Storage 20GB**: ~$2.3/mês
- **Total**: ~$17.30/mês

### Depois (Supabase Free):

- **Banco de dados**: $0/mês (até 500MB)
- **API**: $0/mês (até 2GB transfer)
- **Storage**: $0/mês (até 1GB)
- **Total**: **$0/mês** 🎉

**Economia anual**: ~$207.60/ano

---

## 🔒 Segurança

### Supabase Vantagens:

- ✅ SSL/TLS por padrão
- ✅ Connection pooling automático
- ✅ Backups automáticos diários
- ✅ Point-in-time recovery (Pro plan)
- ✅ Row Level Security (RLS)
- ✅ Dashboard intuitivo

### Configurações Recomendadas:

1. **Habilitar RLS** (opcional, se quiser segurança extra):

```sql
-- Habilitar RLS nas tabelas
ALTER TABLE "Barbeiros" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Agendamentos" ENABLE ROW LEVEL SECURITY;

-- Política: todos podem ler
CREATE POLICY "Permitir leitura publica" ON "Barbeiros"
  FOR SELECT USING (true);

CREATE POLICY "Permitir leitura publica" ON "Agendamentos"
  FOR SELECT USING (true);

-- Política: apenas service_role pode escrever (API backend)
-- (O service_role é usado pela connection string de session mode)
```

2. **Configurar IP Whitelist** (opcional):
   - Settings → Database → Restrictions
   - Adicionar IP do ECS NAT Gateway

---

## 🔄 Migração de Dados (Se necessário)

Se você tinha dados no RDS e quer migrar:

### Via pg_dump:

```bash
# 1. Export do RDS
pg_dump -h [RDS-ENDPOINT] -U postgres -d barbearia_db -F c -b -v -f backup.dump

# 2. Import no Supabase
pg_restore -h aws-0-us-east-1.pooler.supabase.com \
  -p 6543 -U postgres.xxxxx -d postgres \
  --no-owner --no-privileges -v backup.dump
```

### Via SQL:

```bash
# 1. Export
pg_dump -h [RDS-ENDPOINT] -U postgres -d barbearia_db > backup.sql

# 2. Import no Supabase SQL Editor
# Cole o conteúdo de backup.sql
```

---

## 🐛 Troubleshooting

### Erro: "Password authentication failed"

- ✅ Verifique a senha do Supabase (Settings → Database)
- ✅ Use a connection string do **Session mode**, não Transaction mode

### Erro: "Connection timeout"

- ✅ Verifique se está usando a porta `6543` (pooling)
- ✅ Verifique se o security group do ECS permite saída para internet

### Erro: "SSL connection required"

- ✅ Adicione `SSL Mode=Require` na connection string

### Tabelas não aparecem:

- ✅ Execute o script SQL no Supabase SQL Editor
- ✅ Verifique em Table Editor se as tabelas existem

---

## 📊 Monitoramento

### Supabase Dashboard:

- **Reports**: Ver uso de CPU, memória, queries
- **Logs**: Ver queries SQL em tempo real
- **API Logs**: Ver requisições REST

### AWS CloudWatch:

- Os logs do ECS continuam no CloudWatch normalmente

---

## ✨ Benefícios Extras do Supabase

1. **API REST automática**: Supabase gera API REST para todas as tabelas
2. **Realtime**: WebSockets para updates em tempo real
3. **Storage**: Pode armazenar imagens dos barbeiros
4. **Auth**: Sistema de autenticação pronto (se quiser migrar do JWT)
5. **Functions**: Edge functions para lógica serverless

---

**Migração concluída!** 🎉

Se tiver dúvidas, consulte:

- [Supabase Docs](https://supabase.com/docs)
- [Connection Pooling Guide](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)
