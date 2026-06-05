package com.argusoft.meetwise.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class FallbackDataService {

    private final ResourceLoader resourceLoader;
    private final Map<String, String> cache = new ConcurrentHashMap<>();

    public String loadFallback(String agentName) {
        return cache.computeIfAbsent(agentName, this::readFromClasspath);
    }

    private String readFromClasspath(String agentName) {
        String filename = "classpath:sample-data/" + toFilename(agentName);
        try {
            Resource resource = resourceLoader.getResource(filename);
            return new String(resource.getInputStream().readAllBytes());
        } catch (IOException e) {
            log.warn("No fallback file found for agent '{}', using minimal fallback", agentName);
            return "{\"agent\":\"" + agentName + "\",\"fallback\":true,\"confidenceScore\":0.1,\"influencedBy\":[]}";
        }
    }

    private String toFilename(String agentName) {
        return switch (agentName) {
            case "OrganizationResearchAgent" -> "org_research_fallback.json";
            case "EngagementStrategyAgent"   -> "strategy_fallback.json";
            case "ObjectionPredictionAgent"  -> "objection_fallback.json";
            case "FinalSynthesisAgent"       -> "synthesis_fallback.json";
            default -> agentName.toLowerCase() + "_fallback.json";
        };
    }
}
