-- ============================================
-- Script de Criação do Schema - Barbearia Imperial
-- Execute este script no Supabase SQL Editor
-- ============================================

-- Criar tabela Barbeiros (alinhado ao EF: apenas Id e Nome)
CREATE TABLE IF NOT EXISTS "Barbeiros" (
    "Id" SERIAL PRIMARY KEY,
    "Nome" VARCHAR(100) NOT NULL
);

-- Criar tabela Agendamentos (alinhado ao EF atual)
CREATE TABLE IF NOT EXISTS "Agendamentos" (
    "Id" SERIAL PRIMARY KEY,
    "NomeBarbeiro" VARCHAR(100) NOT NULL,
    "NomeCliente" VARCHAR(100) NOT NULL,
    "DataHora" TIMESTAMP WITH TIME ZONE NOT NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Agendado'
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_agendamentos_data 
    ON "Agendamentos"("DataHora");

CREATE INDEX IF NOT EXISTS idx_agendamentos_status 
    ON "Agendamentos"("Status");

CREATE INDEX IF NOT EXISTS idx_agendamentos_barbeiro 
    ON "Agendamentos"("NomeBarbeiro");

CREATE INDEX IF NOT EXISTS idx_agendamentos_cliente 
    ON "Agendamentos"("NomeCliente");

-- (Campo Telefone removido para alinhar com o modelo)

-- Inserir barbeiros iniciais (apenas Nome, alinhado ao EF)
INSERT INTO "Barbeiros" ("Nome") VALUES
    ('João Silva'),
    ('Pedro Santos'),
    ('Carlos Lima');

-- Verificar se as tabelas foram criadas
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verificar barbeiros inseridos
SELECT * FROM "Barbeiros";

-- Exibir estrutura das tabelas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name IN ('Barbeiros', 'Agendamentos')
ORDER BY table_name, ordinal_position;
