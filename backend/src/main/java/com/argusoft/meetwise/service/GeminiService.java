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
                        "maxOutputTokens", maxTokens,
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
            return (String) part.get("text");
        } catch (Exception e) {
            throw new MeetwiseException("Failed to parse Gemini response", e);
        }
    }
}
