package com.argusoft.meetwise.service;

import com.argusoft.meetwise.dto.KnowledgeChunkDto;
import com.argusoft.meetwise.repository.KnowledgeChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Semantic retrieval over knowledge_chunks using pgvector cosine similarity.
 * Never throws — returns an empty list on any failure so agents degrade gracefully.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KnowledgeRetrievalService {

    private static final double SIMILARITY_THRESHOLD = 0.30;
    private static final int    MAX_LIMIT            = 5;

    private final KnowledgeChunkRepository knowledgeChunkRepository;
    private final EmbeddingService         embeddingService;

    /**
     * Retrieves up to {@code limit} chunks most semantically similar to {@code query}.
     * Silently returns an empty list if embedding fails or pgvector is unavailable.
     */
    public List<KnowledgeChunkDto> retrieveRelevantContext(String query, int limit) {
        if (query == null || query.isBlank()) return List.of();

        try {
            List<Double> embedding = embeddingService.generateEmbedding(query);
            if (embedding.isEmpty()) {
                log.debug("[RAG] Embedding unavailable — skipping retrieval");
                return List.of();
            }

            int effectiveLimit = Math.min(limit, MAX_LIMIT);
            List<KnowledgeChunkDto> results = knowledgeChunkRepository.findSimilar(
                    embedding, effectiveLimit, SIMILARITY_THRESHOLD);

            if (!results.isEmpty()) {
                log.info("[RAG] {} chunk(s) retrieved | query: {}…",
                        results.size(), query.substring(0, Math.min(60, query.length())));
            }
            return results;

        } catch (Exception e) {
            log.warn("[RAG] Retrieval failed ({}); agents will continue without RAG", e.getMessage());
            return List.of();
        }
    }
}
