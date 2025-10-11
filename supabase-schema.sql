-- ============================================
-- Script de Criação do Schema - Barbearia Imperial
-- Execute este script no Supabase SQL Editor
-- ============================================

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
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Agendado',
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

CREATE INDEX IF NOT EXISTS idx_agendamentos_telefone 
    ON "Agendamentos"("Telefone");

-- Inserir barbeiros iniciais
INSERT INTO "Barbeiros" ("Nome", "Especialidade") VALUES
    ('João Silva', 'Cortes modernos e barbas'),
    ('Pedro Santos', 'Especialista em degradê'),
    ('Carlos Lima', 'Barbas e finalização')
ON CONFLICT DO NOTHING;

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
