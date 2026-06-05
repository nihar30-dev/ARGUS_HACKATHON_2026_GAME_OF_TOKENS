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
public class EngagementStrategyAgent implements Agent {

    private final GeminiClientService geminiClient;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()  { return "EngagementStrategyAgent"; }
    @Override public int    getOrder() { return 3; }

    @Override
    public AgentOutput execute(AgentContext context) {
        String researchJson = context.getOutput("OrganizationResearchAgent");
        String personaJson  = context.getOutput("StakeholderPersonaAgent");
        String offering     = context.getMeetingRequest().getOfferingDescription();

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            String result = geminiClient.generateJson(
                    systemInstruction(),
                    userPrompt(researchJson, personaJson, offering),
                    1000);

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
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent"))
                .usedGemini(usedGemini)
                .inputSummary("Research + Persona for " + context.getMeetingRequest().getOrganizationName())
                .outputSummary("Meeting strategy with positioning and value proposition")
                .build();
    }

    private String systemInstruction() {
        return """
                You are a senior B2B sales strategist. Create a targeted engagement strategy for the meeting described below.
                Return ONLY a valid JSON object — no markdown, no explanation:
                {
                  "agent": "EngagementStrategyAgent",
                  "meetingGoal": "specific goal for this meeting",
                  "positioning": "how to position the offering for this stakeholder",
                  "valueProposition": "tailored 1-sentence value proposition",
                  "successCriteria": ["criterion1", "criterion2"],
                  "openingApproach": "how to open the meeting",
                  "keyMessages": ["message1", "message2", "message3"],
                  "confidenceScore": 0.88,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent"]
                }
                """;
    }

    private String userPrompt(String research, String persona, String offering) {
        return "Organization Research:\n" + research
                + "\n\nStakeholder Persona:\n" + persona
                + "\n\nOur Offering:\n" + offering;
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
