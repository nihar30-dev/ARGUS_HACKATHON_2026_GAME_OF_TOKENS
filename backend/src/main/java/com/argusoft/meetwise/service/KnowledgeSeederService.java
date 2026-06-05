package com.argusoft.meetwise.service;

import com.argusoft.meetwise.dto.KnowledgeIngestionRequest;
import com.argusoft.meetwise.repository.KnowledgeChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * On startup, seeds the knowledge_chunks table from medplat_knowledge.txt
 * if the table is empty.  Silently skips if pgvector is unavailable or
 * the Gemini API key is not set.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KnowledgeSeederService {

    private final KnowledgeIngestionService ingestionService;
    private final KnowledgeChunkRepository  knowledgeChunkRepository;

    @EventListener(ApplicationReadyEvent.class)
    public void seedKnowledgeBase() {
        try {
            long existing = knowledgeChunkRepository.countAll();
            if (existing > 0) {
                log.info("[Seeder] Knowledge base already contains {} chunk(s) — skipping seed", existing);
                return;
            }

            String text = readClasspathFile("sample-data/medplat_knowledge.txt");
            if (text == null || text.isBlank()) {
                log.warn("[Seeder] sample-data/medplat_knowledge.txt not found — skipping auto-seed");
                return;
            }

            log.info("[Seeder] Seeding knowledge base from medplat_knowledge.txt…");
            int created = ingestionService.ingest(new KnowledgeIngestionRequest(
                    "MEDplat & Digital Health Knowledge",
                    "PRODUCT_KNOWLEDGE",
                    "auto_seed",
                    text,
                    "{\"seeded\":true,\"source\":\"medplat_knowledge.txt\"}"
            ));
            log.info("[Seeder] Knowledge base seeded: {} chunk(s) created", created);

        } catch (Exception e) {
            // pgvector table may not exist in dev without the migration
            log.warn("[Seeder] Knowledge base seeding skipped: {} (RAG will be unavailable)", e.getMessage());
        }
    }

    private String readClasspathFile(String path) {
        try {
            return new ClassPathResource(path).getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException e) {
            return null;
        }
    }
}
