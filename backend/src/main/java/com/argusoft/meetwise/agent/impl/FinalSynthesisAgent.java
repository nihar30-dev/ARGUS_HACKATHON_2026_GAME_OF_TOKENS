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
public class FinalSynthesisAgent implements Agent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override
    public String getName() { return "FinalSynthesisAgent"; }

    @Override
    public int getOrder() { return 6; }

    @Override
    public AgentOutput execute(AgentContext context) {
        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String prompt = buildPrompt(context);
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
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent",
                        "EngagementStrategyAgent", "ObjectionPredictionAgent", "CriticValidatorAgent"))
                .usedGemini(usedGemini)
                .inputSummary("All 5 prior agent outputs")
                .outputSummary("Complete meeting preparation package with executive brief")
                .build();
    }

    private String buildPrompt(AgentContext context) {
        return """
                You are a senior business consultant creating a final meeting preparation package.
                You must incorporate the critic's validation feedback before finalising the output.

                Organization Research:
                %s

                Stakeholder Persona:
                %s

                Engagement Strategy:
                %s

                Objection Predictions:
                %s

                Critic Validation (MUST incorporate improvements listed here):
                %s

                Return a JSON object (raw JSON, no markdown):
                {
                  "agent": "FinalSynthesisAgent",
                  "executiveBrief": "2-3 sentence executive summary",
                  "conversationFlow": [
                    {"phase": "Opening", "duration": "5 min", "approach": "description"},
                    {"phase": "Discovery", "duration": "10 min", "approach": "description"},
                    {"phase": "Demonstration", "duration": "15 min", "approach": "description"},
                    {"phase": "Objection Handling", "duration": "10 min", "approach": "description"},
                    {"phase": "Close", "duration": "5 min", "approach": "description"}
                  ],
                  "topQuestions": ["question1", "question2", "question3"],
                  "objectionResponses": [
                    {"objection": "text", "response": "text"}
                  ],
                  "nextSteps": ["step1", "step2", "step3"],
                  "criticImprovementsApplied": ["improvement1", "improvement2"],
                  "overallConfidenceScore": 0.91,
                  "confidenceScore": 0.91,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent",
                                   "EngagementStrategyAgent", "ObjectionPredictionAgent", "CriticValidatorAgent"]
                }
                """.formatted(
                context.getOutput("OrganizationResearchAgent"),
                context.getOutput("StakeholderPersonaAgent"),
                context.getOutput("EngagementStrategyAgent"),
                context.getOutput("ObjectionPredictionAgent"),
                context.getOutput("CriticValidatorAgent")
        );
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
