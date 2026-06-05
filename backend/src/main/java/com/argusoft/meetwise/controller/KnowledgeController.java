package com.argusoft.meetwise.controller;

import com.argusoft.meetwise.dto.KnowledgeIngestionRequest;
import com.argusoft.meetwise.dto.KnowledgeSearchResponse;
import com.argusoft.meetwise.service.KnowledgeIngestionService;
import com.argusoft.meetwise.service.KnowledgeRetrievalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/knowledge")
@RequiredArgsConstructor
@Slf4j
public class KnowledgeController {

    private final KnowledgeIngestionService ingestionService;
    private final KnowledgeRetrievalService retrievalService;

    /**
     * POST /api/knowledge/ingest
     * Accepts a document, chunks it, generates embeddings, and persists to PostgreSQL.
     */
    @PostMapping("/ingest")
    public ResponseEntity<Map<String, Object>> ingest(
            @Valid @RequestBody KnowledgeIngestionRequest request) {
        log.info("[Knowledge] Ingesting '{}' (sourceType={})", request.title(), request.sourceType());
        int created = ingestionService.ingest(request);
        return ResponseEntity.ok(Map.of(
                "chunksCreated", created,
                "title",         request.title(),
                "sourceType",    request.sourceType()
        ));
    }

    /**
     * GET /api/knowledge/search?query=...&limit=5
     * Semantic search across the knowledge base using cosine similarity.
     */
    @GetMapping("/search")
    public ResponseEntity<KnowledgeSearchResponse> search(
            @RequestParam String query,
            @RequestParam(defaultValue = "5") int limit) {
        var chunks = retrievalService.retrieveRelevantContext(query, limit);
        return ResponseEntity.ok(new KnowledgeSearchResponse(query, chunks.size(), chunks));
    }
}
