package com.argusoft.meetwise.repository;

import com.argusoft.meetwise.dto.KnowledgeChunkDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * JdbcTemplate-based DAO for knowledge_chunks.
 * Uses native pgvector CAST syntax — no additional Java library needed.
 */
@Repository
@RequiredArgsConstructor
@Slf4j
public class KnowledgeChunkRepository {

    private final JdbcTemplate jdbcTemplate;

    /** Persists a chunk with its pre-computed embedding vector. */
    public void save(UUID id,
                     String title,
                     String sourceType,
                     String sourceName,
                     String chunkText,
                     List<Double> embedding,
                     String metadata) {

        String vectorStr = toVectorString(embedding);
        Timestamp now    = Timestamp.from(Instant.now());

        jdbcTemplate.update("""
                INSERT INTO knowledge_chunks
                    (id, title, source_type, source_name, chunk_text, embedding, metadata, created_at, updated_at)
                VALUES
                    (?, ?, ?, ?, ?, CAST(? AS vector), CAST(? AS jsonb), ?, ?)
                """,
                id,
                title,
                sourceType,
                sourceName != null ? sourceName : "",
                chunkText,
                vectorStr,
                metadata   != null ? metadata   : "{}",
                now,
                now
        );
    }

    /**
     * Cosine-similarity search.
     * Returns up to {@code limit} chunks whose similarity exceeds {@code threshold}.
     */
    public List<KnowledgeChunkDto> findSimilar(List<Double> queryEmbedding,
                                                int limit,
                                                double threshold) {
        String emb = toVectorString(queryEmbedding);

        return jdbcTemplate.query("""
                SELECT  id, title, source_type, source_name, chunk_text, metadata,
                        1 - (embedding <=> CAST(? AS vector)) AS similarity
                FROM    knowledge_chunks
                WHERE   embedding IS NOT NULL
                  AND   1 - (embedding <=> CAST(? AS vector)) > ?
                ORDER   BY embedding <=> CAST(? AS vector)
                LIMIT   ?
                """,
                (rs, rowNum) -> new KnowledgeChunkDto(
                        UUID.fromString(rs.getString("id")),
                        rs.getString("title"),
                        rs.getString("source_type"),
                        rs.getString("source_name"),
                        rs.getString("chunk_text"),
                        rs.getDouble("similarity"),
                        rs.getString("metadata")
                ),
                emb, emb, threshold, emb, limit
        );
    }

    /** Total rows — used by the startup seeder to skip re-seeding. */
    public long countAll() {
        Long n = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM knowledge_chunks", Long.class);
        return n != null ? n : 0L;
    }

    // -----------------------------------------------------------------------

    /** Converts a list of doubles to the pgvector text format: [v1,v2,...] */
    private String toVectorString(List<Double> embedding) {
        return "[" + embedding.stream()
                .map(d -> String.format("%.8f", d))
                .collect(Collectors.joining(",")) + "]";
    }
}
