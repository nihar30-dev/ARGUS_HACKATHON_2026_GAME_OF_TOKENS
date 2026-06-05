package com.argusoft.meetwise.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Unified LLM entry point for all agents.
 * Switch providers by setting llm.provider=gemini|claude in application.properties
 * or via the LLM_PROVIDER environment variable.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LlmService {

    private final GeminiService geminiService;
    private final ClaudeService claudeService;

    @Value("${llm.provider:gemini}")
    private String provider;

    public String generate(String prompt) {
        if ("claude".equalsIgnoreCase(provider)) return claudeService.generate(prompt);
        return geminiService.generate(prompt);
    }

    public String generate(String prompt, int maxTokens) {
        log.info("[LLM] provider={} maxTokens={}", provider, maxTokens);
        if ("claude".equalsIgnoreCase(provider)) return claudeService.generate(prompt, maxTokens);
        return geminiService.generate(prompt, maxTokens);
    }

    public String getActiveProvider() {
        return provider;
    }
}
