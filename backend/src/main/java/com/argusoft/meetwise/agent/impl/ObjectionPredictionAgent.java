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
public class ObjectionPredictionAgent implements Agent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override
    public String getName() { return "ObjectionPredictionAgent"; }

    @Override
    public int getOrder() { return 4; }

    @Override
    public AgentOutput execute(AgentContext context) {
        String researchJson  = context.getOutput("OrganizationResearchAgent");
        String personaJson   = context.getOutput("StakeholderPersonaAgent");
        String strategyJson  = context.getOutput("EngagementStrategyAgent");

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String prompt = buildPrompt(researchJson, personaJson, strategyJson);
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
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"))
                .usedGemini(usedGemini)
                .inputSummary("Research + Persona + Strategy outputs")
                .outputSummary("Top objections with counter-responses and risks")
                .build();
    }

    private String buildPrompt(String research, String persona, String strategy) {
        return """
                You are a devil's advocate expert. Predict objections for this sales meeting.

                Organization Research:
                %s

                Stakeholder Persona:
                %s

                Proposed Engagement Strategy:
                %s

                Return a JSON object (raw JSON, no markdown):
                {
                  "agent": "ObjectionPredictionAgent",
                  "objections": [
                    {
                      "objection": "specific objection text",
                      "likelihood": 0.9,
                      "category": "price|technical|timing|competition|trust",
                      "counterResponse": "how to respond to this objection"
                    }
                  ],
                  "topRisks": ["risk1", "risk2"],
                  "confidenceScore": 0.82,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"]
                }
                """.formatted(research, persona, strategy);
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
