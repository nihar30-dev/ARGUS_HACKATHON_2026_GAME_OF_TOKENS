package com.argusoft.meetwise.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Generates 768-dimensional embeddings via Gemini text-embedding-004.
 *
 * Returns an empty list — never throws — when:
 *  - GEMINI_API_KEY is not configured
 *  - the API call fails for any reason
 *  - the response is malformed
 */
@Service
@Slf4j
public class EmbeddingService {

    private static final int MAX_TEXT_CHARS = 8_000;

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.embedding.model:text-embedding-004}")
    private String embeddingModel;

    private final RestTemplate restTemplate;

    public EmbeddingService(@Qualifier("geminiRestTemplate") RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    /**
     * Calls Gemini embedContent API and returns the embedding values.
     * Safe to call unconditionally — returns {@code List.of()} on any failure.
     */
    public List<Double> generateEmbedding(String text) {
        if (apiKey == null || apiKey.isBlank()) {
            log.debug("[Embedding] GEMINI_API_KEY not set — skipping embedding");
            return List.of();
        }
        if (text == null || text.isBlank()) return List.of();

        String safe = text.length() > MAX_TEXT_CHARS
                ? text.substring(0, MAX_TEXT_CHARS) : text;

        try {
            // API key is intentionally not logged
            String url = "https://generativelanguage.googleapis.com/v1beta/models/"
                    + embeddingModel + ":embedContent?key=" + apiKey;

            Map<String, Object> body = Map.of(
                    "content", Map.of("parts", List.of(Map.of("text", safe)))
            );

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(url, body, Map.class);

            if (response == null || !response.containsKey("embedding")) {
                log.warn("[Embedding] Empty or missing 'embedding' key in response");
                return List.of();
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> embeddingObj = (Map<String, Object>) response.get("embedding");
            @SuppressWarnings("unchecked")
            List<Number> values = (List<Number>) embeddingObj.get("values");

            if (values == null || values.isEmpty()) {
                log.warn("[Embedding] Response contained empty values array");
                return List.of();
            }

            return values.stream().map(Number::doubleValue).collect(Collectors.toList());

        } catch (Exception e) {
            log.warn("[Embedding] API call failed: {}", e.getMessage());
            return List.of();
        }
    }
}
