package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentOutput;
import com.argusoft.meetwise.service.FallbackDataService;
import com.argusoft.meetwise.service.GeminiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class OrganizationResearchAgent implements Agent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override
    public String getName() { return "OrganizationResearchAgent"; }

    @Override
    public int getOrder() { return 1; }

    @Override
    public AgentOutput execute(AgentContext context) {
        var meeting = context.getMeetingRequest();
        String inputSummary = "Organization: " + meeting.getOrganizationName()
                + " | Objective: " + meeting.getMeetingObjective();

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
            log.info("[{}] Demo mode — loaded fallback JSON", getName());
        } else {
            try {
                String prompt = buildPrompt(meeting.getOrganizationName(),
                        meeting.getMeetingObjective(), meeting.getOfferingDescription());
                outputJson = geminiService.generate(prompt);
                usedGemini = true;
            } catch (Exception e) {
                log.warn("[{}] Gemini failed ({}), using fallback", getName(), e.getMessage());
                outputJson = fallbackDataService.loadFallback(getName());
            }
        }

        double confidence = extractConfidence(outputJson);
        return AgentOutput.builder()
                .agentName(getName())
                .outputJson(outputJson)
                .confidenceScore(confidence)
                .influencedBy(List.of())
                .usedGemini(usedGemini)
                .inputSummary(inputSummary)
                .outputSummary("Organization analysis for " + meeting.getOrganizationName())
                .build();
    }

    private String buildPrompt(String orgName, String objective, String offering) {
        return """
                You are an expert business intelligence analyst.
                Analyze the following organization for a meeting preparation context.

                Organization: %s
                Meeting Objective: %s
                Our Offering: %s

                Return a JSON object with this exact structure (no markdown, raw JSON only):
                {
                  "agent": "OrganizationResearchAgent",
                  "organizationSummary": "2-3 sentence summary",
                  "businessPriorities": ["priority1", "priority2", "priority3"],
                  "painPoints": ["pain1", "pain2", "pain3"],
                  "partnershipOpportunities": ["opportunity1", "opportunity2"],
                  "industryContext": "relevant industry context",
                  "confidenceScore": 0.85,
                  "influencedBy": []
                }
                """.formatted(orgName, objective, offering);
    }

    private double extractConfidence(String json) {
        try {
            int idx = json.indexOf("\"confidenceScore\"");
            if (idx == -1) return 0.5;
            int colon = json.indexOf(":", idx);
            int comma = json.indexOf(",", colon);
            int brace = json.indexOf("}", colon);
            int end = Math.min(comma == -1 ? brace : comma, brace == -1 ? comma : brace);
            return Double.parseDouble(json.substring(colon + 1, end).trim());
        } catch (Exception e) {
            return 0.5;
        }
    }
}
