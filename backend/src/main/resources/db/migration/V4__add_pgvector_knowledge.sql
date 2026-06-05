-- ============================================================
-- V4: pgvector RAG Knowledge Layer
-- Requires pgvector extension on the PostgreSQL instance.
-- ============================================================

-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Knowledge chunks table
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    title       VARCHAR(255)  NOT NULL,
    source_type VARCHAR(100)  NOT NULL,
    source_name VARCHAR(255),
    chunk_text  TEXT          NOT NULL,
    embedding   VECTOR(768),
    metadata    JSONB         DEFAULT '{}',
    created_at  TIMESTAMP     DEFAULT NOW(),
    updated_at  TIMESTAMP     DEFAULT NOW()
);

-- HNSW index for fast cosine-similarity search
CREATE INDEX IF NOT EXISTS idx_knowledge_embedding_hnsw
    ON knowledge_chunks USING hnsw (embedding vector_cosine_ops);

-- Filter indexes
CREATE INDEX IF NOT EXISTS idx_knowledge_source_type ON knowledge_chunks (source_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_source_name ON knowledge_chunks (source_name);
