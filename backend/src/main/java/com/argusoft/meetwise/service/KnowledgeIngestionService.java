package com.argusoft.meetwise.service;

import com.argusoft.meetwise.dto.KnowledgeIngestionRequest;
import com.argusoft.meetwise.repository.KnowledgeChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Accepts plain text, slices it into overlapping chunks,
 * generates embeddings, and persists each chunk to knowledge_chunks.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KnowledgeIngestionService {

    private static final int CHUNK_SIZE    = 900;
    private static final int CHUNK_OVERLAP = 100;
    private static final int MIN_CHUNK_LEN = 50;

    private final KnowledgeChunkRepository knowledgeChunkRepository;
    private final EmbeddingService         embeddingService;

    /**
     * Ingests a document.
     * @return number of chunks successfully stored with embeddings
     */
    public int ingest(KnowledgeIngestionRequest request) {
        if (request.text() == null || request.text().isBlank()) return 0;

        List<String> chunks = chunkText(request.text().trim(), CHUNK_SIZE, CHUNK_OVERLAP);
        int created = 0;

        for (int i = 0; i < chunks.size(); i++) {
            String chunk = chunks.get(i);
            List<Double> embedding = embeddingService.generateEmbedding(chunk);

            if (embedding.isEmpty()) {
                log.warn("[Ingest] Embedding unavailable for chunk {}/{} of '{}' — skipping",
                        i + 1, chunks.size(), request.title());
                continue;
            }

            try {
                knowledgeChunkRepository.save(
                        UUID.randomUUID(),
                        request.title(),
                        request.sourceType(),
                        request.sourceName(),
                        chunk,
                        embedding,
                        request.metadata() != null ? request.metadata() : "{}"
                );
                created++;
            } catch (Exception e) {
                log.error("[Ingest] Failed to persist chunk {}: {}", i + 1, e.getMessage());
            }
        }

        log.info("[Ingest] '{}' → {}/{} chunk(s) stored", request.title(), created, chunks.size());
        return created;
    }

    // -----------------------------------------------------------------------
    // Sliding-window chunker
    // -----------------------------------------------------------------------

    private List<String> chunkText(String text, int chunkSize, int overlap) {
        List<String> chunks = new ArrayList<>();
        int start = 0;

        while (start < text.length()) {
            int end = Math.min(start + chunkSize, text.length());

            // Snap to word boundary so we don't cut mid-word
            if (end < text.length()) {
                int lastSpace = text.lastIndexOf(' ', end);
                if (lastSpace > start + chunkSize / 2) end = lastSpace;
            }

            String chunk = text.substring(start, end).trim();
            if (chunk.length() >= MIN_CHUNK_LEN) chunks.add(chunk);

            if (end >= text.length()) break;
            start = Math.max(0, end - overlap);
        }

        return chunks;
    }
}
