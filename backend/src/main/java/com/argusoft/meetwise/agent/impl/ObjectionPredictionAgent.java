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
public class ObjectionPredictionAgent implements Agent {

    private final GeminiClientService geminiClient;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()  { return "ObjectionPredictionAgent"; }
    @Override public int    getOrder() { return 4; }

    @Override
    public AgentOutput execute(AgentContext context) {
        String researchJson = context.getOutput("OrganizationResearchAgent");
        String personaJson  = context.getOutput("StakeholderPersonaAgent");
        String strategyJson = context.getOutput("EngagementStrategyAgent");

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            String result = geminiClient.generateJson(
                    systemInstruction(),
                    userPrompt(researchJson, personaJson, strategyJson),
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
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"))
                .usedGemini(usedGemini)
                .inputSummary("Research + Persona + Strategy outputs")
                .outputSummary("Top objections with counter-responses and risks")
                .build();
    }

    private String systemInstruction() {
        return """
                You are a devil's advocate expert who predicts and pre-empts sales meeting objections.
                Return ONLY a valid JSON object — no markdown, no explanation:
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
                """;
    }

    private String userPrompt(String research, String persona, String strategy) {
        return "Organization Research:\n" + research
                + "\n\nStakeholder Persona:\n" + persona
                + "\n\nProposed Engagement Strategy:\n" + strategy;
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
