package com.argusoft.meetwise.service;

import com.argusoft.meetwise.exception.MeetwiseException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class ClaudeService {

    private final RestTemplate claudeRestTemplate;

    @Value("${claude.api.key:}")
    private String apiKey;

    @Value("${claude.model:claude-sonnet-4-6}")
    private String model;

    @Value("${claude.max-tokens:3072}")
    private int maxTokens;

    @Value("${claude.temperature:0.3}")
    private double temperature;

    private static final String API_URL = "https://api.anthropic.com/v1/messages";

    public ClaudeService(@Qualifier("claudeRestTemplate") RestTemplate claudeRestTemplate) {
        this.claudeRestTemplate = claudeRestTemplate;
    }

    public String generate(String prompt) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new MeetwiseException("CLAUDE_API_KEY is not configured");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");

        Map<String, Object> requestBody = Map.of(
                "model", model,
                "max_tokens", maxTokens,
                "temperature", temperature,
                "messages", List.of(Map.of("role", "user", "content", prompt))
        );

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = claudeRestTemplate.postForObject(API_URL, request, Map.class);
            return extractText(response);
        } catch (Exception e) {
            log.error("Claude API call failed: {}", e.getMessage());
            throw new MeetwiseException("Claude API call failed: " + e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    private String extractText(Map<String, Object> responseBody) {
        try {
            List<?> content = (List<?>) responseBody.get("content");
            Map<?, ?> block = (Map<?, ?>) content.get(0);
            return (String) block.get("text");
        } catch (Exception e) {
            throw new MeetwiseException("Failed to parse Claude response", e);
        }
    }
}
