# ✅ Checklist de Migração para Supabase

## 📋 Antes de Começar

- [ ] Conta criada no Supabase (https://supabase.com)
- [ ] AWS CLI configurado (`aws configure`)
- [ ] Docker instalado e rodando
- [ ] Terraform instalado

---

## 🚀 Passo a Passo

### 1️⃣ Criar Projeto no Supabase (5 min)

1. Acesse https://supabase.com
2. Clique em **"New Project"**
3. Preencha:
   - **Organization**: Selecione ou crie
   - **Name**: `barbearia-imperial`
   - **Database Password**: [Crie uma senha forte e anote]
   - **Region**: `East US (North Virginia)` ⚠️ Importante: mesma região do ECS
   - **Pricing Plan**: Free (8GB storage, 500MB DB, 2GB bandwidth)
4. Aguarde ~2 minutos para provisionar
5. ✅ Projeto criado!

---

### 2️⃣ Obter Connection String (2 min)

1. No dashboard do Supabase, vá em **Settings** (⚙️ no menu lateral)
2. Clique em **Database**
3. Role até a seção **Connection String**
4. Selecione **Session mode** (não use Transaction mode!)
5. Copie a string que aparece:

```
postgresql://postgres.[PROJECT-REF]:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

6. ⚠️ Substitua `[YOUR-PASSWORD]` pela senha que você criou
7. ✅ Connection string obtida!

**Exemplo:**

```
postgresql://postgres.abcdefghijklmnop:MinhaSenhaForte123!@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

---

### 3️⃣ Criar Tabelas no Supabase (3 min)

1. No Supabase, vá em **SQL Editor** (</> no menu lateral)
2. Clique em **New Query**
3. Cole o conteúdo do arquivo `supabase-schema.sql`
4. Clique em **RUN** (ou pressione Ctrl+Enter)
5. Verifique a saída:
   - ✅ "CREATE TABLE" para Barbeiros e Agendamentos
   - ✅ "CREATE INDEX" para os índices
   - ✅ "INSERT 0 3" para os barbeiros
6. Vá em **Table Editor** no menu lateral
7. Confirme que as tabelas **Barbeiros** e **Agendamentos** aparecem
8. ✅ Tabelas criadas!

---

### 4️⃣ Configurar Terraform (3 min)

1. Abra o terminal no projeto:

```bash
cd barbearia-infra
```

2. Copie o arquivo de exemplo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edite o arquivo `terraform.tfvars`:

```bash
nano terraform.tfvars
# ou
code terraform.tfvars
```

4. Cole sua connection string:

```hcl
supabase_connection_string = "postgresql://postgres.xxxxx:SuaSenha@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
api_domain_name            = "api.victorbrandao.tech"
```

5. Salve e feche (Ctrl+X, Y, Enter no nano)
6. ✅ Terraform configurado!

---

### 5️⃣ Executar Deploy Automatizado (5-10 min)

**Opção A: Script Automatizado (Recomendado)**

```bash
cd ..  # Voltar para raiz do projeto
./deploy-supabase.sh
```

O script vai:

- ✅ Remover RDS antigo (se existir)
- ✅ Aplicar nova configuração Terraform
- ✅ Build da imagem Docker
- ✅ Push para ECR
- ✅ Force deploy no ECS
- ✅ Testar a API

**Opção B: Manual**

```bash
# 1. Remover RDS
cd barbearia-infra
terraform destroy -auto-approve \
    -target=aws_db_instance.barbearia_db \
    -target=aws_db_subnet_group.db_subnet_group \
    -target=aws_security_group.db_sg

# 2. Aplicar Terraform
terraform init -upgrade
terraform apply

# 3. Build e Push
cd ..
docker build -t barbeariaapi-api:latest .
docker tag barbeariaapi-api:latest \
    428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest

aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    428014821600.dkr.ecr.us-east-1.amazonaws.com

docker push 428014821600.dkr.ecr.us-east-1.amazonaws.com/barbearia-api-repo:latest

# 4. Deploy ECS
aws ecs update-service \
    --cluster barbearia-cluster \
    --service barbearia-api-service \
    --force-new-deployment \
    --region us-east-1

# 5. Aguardar
aws ecs wait services-stable \
    --cluster barbearia-cluster \
    --services barbearia-api-service \
    --region us-east-1
```

---

### 6️⃣ Verificar Deploy (2 min)

1. **Logs do ECS:**

```bash
aws logs tail /ecs/barbearia-api --follow --region us-east-1
```

Procure por:

```
✅ info: Microsoft.Hosting.Lifetime[0]
      Now listening on: http://+:80
✅ info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

2. **Testar API:**

```bash
# Listar barbeiros
curl https://api.victorbrandao.tech/api/barbeiros

# Health check
curl -I https://api.victorbrandao.tech/api/barbeiros
```

Esperado:

```json
[
  {
    "id": 1,
    "nome": "João Silva",
    "especialidade": "Cortes modernos e barbas"
  },
  {
    "id": 2,
    "nome": "Pedro Santos",
    "especialidade": "Especialista em degradê"
  },
  { "id": 3, "nome": "Carlos Lima", "especialidade": "Barbas e finalização" }
]
```

3. **Testar Frontend:**

- Cliente: https://api.victorbrandao.tech/index.html
- Admin: https://api.victorbrandao.tech/admin.html (admin / password123)

4. ✅ Tudo funcionando!

---

## 🎉 Migração Concluída!

### 📊 Comparação

| Item          | AWS RDS    | Supabase Free       |
| ------------- | ---------- | ------------------- |
| **Custo/mês** | ~$17.30    | $0.00               |
| **Storage**   | 20GB       | 8GB (suficiente)    |
| **Database**  | 500MB      | 500MB               |
| **Bandwidth** | Pago       | 2GB/mês grátis      |
| **Backups**   | Manual     | Automático (diário) |
| **Dashboard** | CloudWatch | Supabase UI         |
| **Logs**      | CloudWatch | Integrado           |
| **Realtime**  | ❌         | ✅ WebSockets       |
| **API REST**  | Manual     | ✅ Auto-gerada      |
| **Auth**      | Manual     | ✅ Integrada        |

### 💰 Economia Anual: **$207.60**

---

## 🛠️ Manutenção

### Monitorar Uso (Supabase Dashboard)

1. **Database**: Settings → Database Usage

   - Storage usado
   - Conexões ativas
   - Queries/segundo

2. **Logs**: Logs → Postgres Logs

   - Ver todas as queries
   - Identificar queries lentas

3. **Reports**: Reports
   - Gráficos de uso
   - Picos de tráfego

### Backups

**Automático:**

- Supabase faz backup diário automaticamente (Free plan: 7 dias de retenção)

**Manual (se necessário):**

```bash
# Export
pg_dump -h aws-0-us-east-1.pooler.supabase.com \
    -p 6543 -U postgres.xxxxx -d postgres \
    --no-owner --no-privileges > backup-$(date +%Y%m%d).sql

# Restore (se necessário)
psql -h aws-0-us-east-1.pooler.supabase.com \
    -p 6543 -U postgres.xxxxx -d postgres < backup-20250101.sql
```

### Escalar (se necessário)

Se ultrapassar os limites do Free plan:

- **Pro Plan**: $25/mês
  - 8GB storage → 100GB
  - 500MB DB → 8GB
  - 50GB bandwidth
  - Point-in-time recovery
  - Suporte prioritário

---

## 🐛 Troubleshooting

### Erro: "Failed to connect to database"

- ✅ Verifique a connection string em `terraform.tfvars`
- ✅ Confirme que está usando porta `6543` (não 5432)
- ✅ Verifique se a senha está correta

### Erro: "SSL connection required"

- ✅ Supabase sempre usa SSL
- ✅ Entity Framework detecta automaticamente

### Tabelas não aparecem

- ✅ Execute `supabase-schema.sql` novamente
- ✅ Verifique em Table Editor

### API retorna 500

- ✅ Veja logs: `aws logs tail /ecs/barbearia-api --follow`
- ✅ Verifique variáveis de ambiente no ECS Task Definition

### Deploy não atualiza

- ✅ Espere 2-3 minutos
- ✅ Force new deployment novamente
- ✅ Verifique se a imagem foi para ECR: `aws ecr list-images --repository-name barbearia-api-repo`

---

## 📚 Links Úteis

- **Supabase Dashboard**: https://supabase.com/dashboard
- **Documentação**: https://supabase.com/docs
- **Connection Pooling**: https://supabase.com/docs/guides/database/connecting-to-postgres
- **API Auto-gerada**: https://supabase.com/docs/guides/api

---

## ✅ Status Final

- [x] RDS removido
- [x] Supabase configurado
- [x] Tabelas criadas
- [x] Terraform atualizado
- [x] Deploy realizado
- [x] API funcionando
- [x] Frontend funcionando
- [x] Economia de $17/mês

**🎊 Parabéns! Sistema migrado com sucesso!**
