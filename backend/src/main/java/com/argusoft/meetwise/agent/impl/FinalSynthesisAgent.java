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
public class FinalSynthesisAgent implements Agent {

    private final GeminiClientService geminiClient;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()  { return "FinalSynthesisAgent"; }
    @Override public int    getOrder() { return 6; }

    @Override
    public AgentOutput execute(AgentContext context) {
        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            // FinalSynthesisAgent gets the most tokens — its output is the full meeting brief
            String result = geminiClient.generateJson(
                    systemInstruction(),
                    userPrompt(context),
                    1200);

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
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent",
                        "EngagementStrategyAgent", "ObjectionPredictionAgent", "CriticValidatorAgent"))
                .usedGemini(usedGemini)
                .inputSummary("All 5 prior agent outputs")
                .outputSummary("Complete meeting preparation package with executive brief")
                .build();
    }

    private String systemInstruction() {
        return """
                You are a senior business consultant producing the final meeting preparation package.
                You MUST incorporate every improvement listed in the Critic Validation section.
                Return ONLY a valid JSON object — no markdown, no explanation:
                {
                  "agent": "FinalSynthesisAgent",
                  "executiveBrief": "2-3 sentence executive summary",
                  "conversationFlow": [
                    {"phase": "Opening",            "duration": "5 min",  "approach": "description"},
                    {"phase": "Discovery",          "duration": "10 min", "approach": "description"},
                    {"phase": "Demonstration",      "duration": "15 min", "approach": "description"},
                    {"phase": "Objection Handling", "duration": "10 min", "approach": "description"},
                    {"phase": "Close",              "duration": "5 min",  "approach": "description"}
                  ],
                  "topQuestions": ["question1", "question2", "question3"],
                  "objectionResponses": [{"objection": "text", "response": "text"}],
                  "nextSteps": ["step1", "step2", "step3"],
                  "criticImprovementsApplied": ["improvement1", "improvement2"],
                  "overallConfidenceScore": 0.91,
                  "confidenceScore": 0.91,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent",
                                   "EngagementStrategyAgent", "ObjectionPredictionAgent", "CriticValidatorAgent"]
                }
                """;
    }

    private String userPrompt(AgentContext context) {
        return "Organization Research:\n" + context.getOutput("OrganizationResearchAgent")
                + "\n\nStakeholder Persona:\n" + context.getOutput("StakeholderPersonaAgent")
                + "\n\nEngagement Strategy:\n" + context.getOutput("EngagementStrategyAgent")
                + "\n\nObjection Predictions:\n" + context.getOutput("ObjectionPredictionAgent")
                + "\n\nCritic Validation (incorporate all improvements):\n"
                + context.getOutput("CriticValidatorAgent");
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
