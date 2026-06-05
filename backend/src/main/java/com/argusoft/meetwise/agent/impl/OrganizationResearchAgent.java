package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentOutput;
import com.argusoft.meetwise.service.FallbackDataService;
import com.argusoft.meetwise.service.GeminiClientService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class OrganizationResearchAgent implements Agent {

    private final GeminiClientService geminiClient;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()  { return "OrganizationResearchAgent"; }
    @Override public int    getOrder() { return 1; }

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
            String result = geminiClient.generateJson(
                    systemInstruction(),
                    userPrompt(meeting.getOrganizationName(),
                               meeting.getMeetingObjective(),
                               meeting.getOfferingDescription()),
                    900);

            if (result != null) {
                outputJson = result;
                usedGemini = true;
            } else {
                log.warn("[{}] Gemini unavailable — using fallback", getName());
                outputJson = fallbackDataService.loadFallback(getName());
            }
        }

        return AgentOutput.builder()
                .agentName(getName())
                .outputJson(outputJson)
                .confidenceScore(extractConfidence(outputJson))
                .influencedBy(List.of())
                .usedGemini(usedGemini)
                .inputSummary(inputSummary)
                .outputSummary("Organization analysis for " + meeting.getOrganizationName())
                .build();
    }

    private String systemInstruction() {
        return """
                You are an expert business intelligence analyst preparing for a B2B sales meeting.
                Analyse the provided organization and return ONLY a valid JSON object — no markdown, no explanation:
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
                """;
    }

    private String userPrompt(String orgName, String objective, String offering) {
        return "Organization: " + orgName
                + "\nMeeting Objective: " + objective
                + "\nOur Offering: " + offering;
    }

    private double extractConfidence(String json) {
        try {
            int idx = json.indexOf("\"confidenceScore\"");
            if (idx == -1) return 0.5;
            int colon = json.indexOf(":", idx);
            int comma = json.indexOf(",", colon);
            int brace = json.indexOf("}", colon);
            int end = (comma == -1 || brace < comma) ? brace : comma;
            return Double.parseDouble(json.substring(colon + 1, end).trim());
        } catch (Exception e) {
            return 0.5;
        }
    }
}
