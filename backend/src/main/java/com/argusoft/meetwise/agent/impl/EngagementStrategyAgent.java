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
public class EngagementStrategyAgent implements Agent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override
    public String getName() { return "EngagementStrategyAgent"; }

    @Override
    public int getOrder() { return 3; }

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
            try {
                String prompt = buildPrompt(researchJson, personaJson, offering);
                outputJson = geminiService.generate(prompt);
                usedGemini = true;
            } catch (Exception e) {
                log.warn("[{}] Gemini failed ({}), using fallback", getName(), e.getMessage());
                outputJson = fallbackDataService.loadFallback(getName());
            }
        }

        return AgentOutput.builder()
                .agentName(getName())
                .outputJson(outputJson)
                .confidenceScore(extractConfidence(outputJson))
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent"))
                .usedGemini(usedGemini)
                .inputSummary("Research + Persona outputs for " + context.getMeetingRequest().getOrganizationName())
                .outputSummary("Meeting strategy with positioning and value proposition")
                .build();
    }

    private String buildPrompt(String research, String persona, String offering) {
        return """
                You are a senior sales strategist. Create a targeted meeting engagement strategy.

                Organization Research:
                %s

                Stakeholder Persona:
                %s

                Our Offering:
                %s

                Return a JSON object (raw JSON, no markdown):
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
                """.formatted(research, persona, offering);
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
