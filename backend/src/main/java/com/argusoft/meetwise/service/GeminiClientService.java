package com.argusoft.meetwise.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Single entry point for all Gemini API calls in MeetWise.
 *
 * Returns null instead of throwing so callers can fall back to sample data
 * without needing their own try/catch blocks.
 */
@Service
@Slf4j
public class GeminiClientService {

    private static final int TOKEN_MIN = 800;
    private static final int TOKEN_MAX = 1200;

    // Constructor-injected (final, built once at startup)
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // @Value-injected after construction by Spring — available at call time
    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.api.model:gemini-2.5-flash}")
    private String model;

    @Value("${gemini.api.base-url:https://generativelanguage.googleapis.com/v1beta/models}")
    private String baseUrl;

    @Value("${gemini.temperature:0.3}")
    private double temperature;

    public GeminiClientService(RestTemplateBuilder builder, ObjectMapper objectMapper) {
        // Timeouts set here so GeminiClientService owns its RestTemplate configuration.
        // readTimeout 60 s covers Gemini 2.5 Flash thinking-mode latency.
        this.restTemplate = builder
                .setConnectTimeout(Duration.ofSeconds(10))
                .setReadTimeout(Duration.ofSeconds(60))
                .build();
        this.objectMapper = objectMapper;
    }

    /**
     * Ask Gemini to produce a JSON string.
     *
     * @param systemInstruction Agent role + required output schema (static per agent).
     * @param userPrompt        Input data for this specific request.
     * @param maxOutputTokens   Clamped internally to [{@value TOKEN_MIN}, {@value TOKEN_MAX}].
     * @return Valid JSON string, or {@code null} if the API is unavailable, times out,
     *         or returns non-JSON after one retry.
     */
    public String generateJson(String systemInstruction, String userPrompt, int maxOutputTokens) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("[Gemini] GEMINI_API_KEY not configured — skipping call, returning null");
            return null;
        }

        int tokens = Math.max(TOKEN_MIN, Math.min(TOKEN_MAX, maxOutputTokens));
        String label = describeRequest(systemInstruction);
        log.info("[Gemini] Request [model={}, tokens={}, type='{}']", model, tokens, label);

        String raw = invoke(systemInstruction, userPrompt, tokens);
        if (raw == null) return null;

        if (isValidJson(raw)) {
            log.debug("[Gemini] Response OK ({} chars) [type='{}']", raw.length(), label);
            return raw;
        }

        // Gemini occasionally wraps JSON in markdown fences — retry once
        log.warn("[Gemini] Response was not valid JSON, retrying once [type='{}']", label);
        raw = invoke(systemInstruction, userPrompt, tokens);
        if (raw == null) return null;

        if (isValidJson(raw)) {
            log.info("[Gemini] Retry produced valid JSON [type='{}']", label);
            return raw;
        }

        log.warn("[Gemini] Retry still non-JSON — returning null for fallback [type='{}']", label);
        return null;
    }

    // ── private ────────────────────────────────────────────────────────────────

    private String invoke(String systemInstruction, String userPrompt, int tokens) {
        // Key embedded in query param per Gemini API spec.
        // NEVER log this URL — it contains the API key.
        String url = baseUrl + "/" + model + ":generateContent?key=" + apiKey;

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = new LinkedHashMap<>();
        if (systemInstruction != null && !systemInstruction.isBlank()) {
            body.put("systemInstruction",
                    Map.of("parts", List.of(Map.of("text", systemInstruction))));
        }
        body.put("contents",
                List.of(Map.of("role", "user",
                        "parts", List.of(Map.of("text", userPrompt)))));
        body.put("generationConfig", Map.of(
                "temperature", temperature,
                "maxOutputTokens", tokens,
                "responseMimeType", "application/json"
        ));

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    url, new HttpEntity<>(body, headers), Map.class);
            return extractText(response);
        } catch (ResourceAccessException e) {
            log.error("[Gemini] Timeout or network error: {}", e.getMessage());
        } catch (HttpClientErrorException e) {
            // scrubKey guards against the key appearing in error response bodies
            log.error("[Gemini] Client error {}: {}", e.getStatusCode(), scrubKey(e.getMessage()));
        } catch (HttpServerErrorException e) {
            log.error("[Gemini] Server error {}: {}", e.getStatusCode(), e.getMessage());
        } catch (Exception e) {
            log.error("[Gemini] Unexpected error: {}", e.getMessage());
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    private String extractText(Map<String, Object> response) {
        if (response == null) {
            log.warn("[Gemini] Null response body");
            return null;
        }
        try {
            var candidates = (List<Map<String, Object>>) response.get("candidates");
            var content    = (Map<String, Object>) candidates.get(0).get("content");
            var parts      = (List<Map<String, Object>>) content.get("parts");
            return (String) parts.get(0).get("text");
        } catch (Exception e) {
            log.error("[Gemini] Unexpected response structure: {}", e.getMessage());
            return null;
        }
    }

    private boolean isValidJson(String text) {
        if (text == null || text.isBlank()) return false;
        try {
            objectMapper.readTree(text);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /** First 50 chars of the system instruction — enough context without exposing data. */
    private String describeRequest(String systemInstruction) {
        if (systemInstruction == null || systemInstruction.isBlank()) return "(none)";
        String s = systemInstruction.stripLeading();
        return s.length() <= 50 ? s : s.substring(0, 50) + "…";
    }

    /** Defensive scrub: replace key value if it somehow ends up in an error string. */
    private String scrubKey(String message) {
        if (message == null || apiKey == null || apiKey.isBlank()) return message;
        return message.replace(apiKey, "[REDACTED]");
    }
}
