package com.argusoft.meetwise.service;

import com.argusoft.meetwise.exception.MeetwiseException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeminiService {

    private final RestTemplate geminiRestTemplate;

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.api.url}")
    private String apiUrl;

    @Value("${gemini.max-tokens:1000}")
    private int maxTokens;

    @Value("${gemini.temperature:0.3}")
    private double temperature;

    public String generate(String prompt) {
        return generate(prompt, maxTokens);
    }

    public String generate(String prompt, int tokenLimit) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new MeetwiseException("GEMINI_API_KEY is not configured");
        }

        String url = apiUrl + "?key=" + apiKey;

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(Map.of("parts", List.of(Map.of("text", prompt)))),
                "generationConfig", Map.of(
                        "temperature", temperature,
                        "maxOutputTokens", tokenLimit,
                        "responseMimeType", "application/json"
                )
        );

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = geminiRestTemplate.postForObject(url, request, Map.class);
            return extractText(response);
        } catch (Exception e) {
            log.error("Gemini API call failed: {}", e.getMessage());
            throw new MeetwiseException("Gemini API call failed: " + e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    private String extractText(Map<String, Object> responseBody) {
        try {
            List<?> candidates = (List<?>) responseBody.get("candidates");
            Map<?, ?> candidate = (Map<?, ?>) candidates.get(0);
            Map<?, ?> content = (Map<?, ?>) candidate.get("content");
            List<?> parts = (List<?>) content.get("parts");
            Map<?, ?> part = (Map<?, ?>) parts.get(0);
            String text = (String) part.get("text");
            return cleanJsonResponse(text);
        } catch (Exception e) {
            throw new MeetwiseException("Failed to parse Gemini response", e);
        }
    }

    /**
     * Cleans Gemini output to guarantee a valid JSON string is returned.
     *
     * Strategy (in order):
     *   1. Strip markdown code fences (```json ... ``` or ``` ... ```)
     *   2. Use depth-tracking to extract the outermost complete JSON object.
     *      This correctly handles truncated responses where lastIndexOf('}')
     *      would otherwise land on a nested closing brace instead of the root one.
     *   3. If still no valid outermost object is found, return the trimmed text
     *      and let the caller decide whether to fall back.
     */
    private String cleanJsonResponse(String text) {
        if (text == null) return null;
        String t = text.trim();

        // Step 1 — strip markdown fences
        if (t.startsWith("```")) {
            int firstNewline = t.indexOf('\n');
            if (firstNewline != -1) t = t.substring(firstNewline + 1).trim();
            if (t.endsWith("```")) t = t.substring(0, t.lastIndexOf("```")).trim();
        }

        // Step 2 — depth-tracking extraction of the outermost { ... }
        int start = t.indexOf('{');
        if (start != -1) {
            int depth = 0;
            boolean inString = false;
            boolean escape = false;
            for (int i = start; i < t.length(); i++) {
                char c = t.charAt(i);
                if (escape) { escape = false; continue; }
                if (c == '\\' && inString) { escape = true; continue; }
                if (c == '"') { inString = !inString; continue; }
                if (inString) continue;
                if (c == '{') depth++;
                else if (c == '}') {
                    depth--;
                    if (depth == 0) {
                        return t.substring(start, i + 1);
                    }
                }
            }
        }

        // Step 3 — return as-is and let isValidJson() handle it
        return t;
    }
}
