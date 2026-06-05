package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentResult;
import com.argusoft.meetwise.agent.BaseAgent;
import com.argusoft.meetwise.agent.core.AgentType;
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
public class ObjectionPredictionAgent extends BaseAgent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()         { return "ObjectionPredictionAgent"; }
    @Override public int    getOrder()        { return 4; }
    @Override public AgentType getAgentType() { return AgentType.GEMINI_BASED; }

    @Override
    public AgentResult execute(AgentContext context) {
        String researchJson = getPreviousOutputJson(context, "OrganizationResearchAgent");
        String personaJson  = getPreviousOutputJson(context, "StakeholderPersonaAgent");
        String strategyJson = getPreviousOutputJson(context, "EngagementStrategyAgent");

        addTrace(context, "OrganizationResearchAgent", "INFLUENCE",
                "ObjectionPredictionAgent used org pain points to anticipate resistance");
        addTrace(context, "StakeholderPersonaAgent", "INFLUENCE",
                "ObjectionPredictionAgent predicted objections aligned with stakeholder decision lens");
        addTrace(context, "EngagementStrategyAgent", "INFLUENCE",
                "ObjectionPredictionAgent challenged the proposed strategy by stress-testing its key messages");

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String raw = geminiService.generate(buildPrompt(researchJson, personaJson, strategyJson));
                if (isValidJson(raw)) {
                    outputJson = raw;
                    usedGemini = true;
                } else {
                    log.warn("[{}] Gemini returned invalid JSON, using fallback", getName());
                    outputJson = fallbackDataService.loadFallback(getName());
                }
            } catch (Exception e) {
                log.warn("[{}] Gemini failed ({}), using fallback", getName(), e.getMessage());
                outputJson = fallbackDataService.loadFallback(getName());
            }
        }

        AgentResult result = success(
                outputJson,
                extractConfidence(outputJson),
                List.of("OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"),
                usedGemini,
                "Research + Persona + Strategy outputs",
                "Top objections with counter-responses and risks");

        context.putResult(getName(), result);
        return result;
    }

    private String buildPrompt(String research, String persona, String strategy) {
        return """
                You are a skeptical executive and devil's advocate. Predict objections for this sales meeting.
                Behave like a skeptical executive who does NOT agree with the strategy automatically.
                Minimum 3 objections. Challenge assumptions. Generate evidence requests.

                Organization Research:
                %s

                Stakeholder Persona:
                %s

                Proposed Engagement Strategy:
                %s

                Return raw JSON only (no markdown):
                {
                  "agent": "ObjectionPredictionAgent",
                  "objections": [
                    {
                      "objection": "specific objection text",
                      "risk_level": 0.9,
                      "why_it_may_arise": "root cause explanation",
                      "recommended_response": "how to counter this objection",
                      "evidence_needed": "what proof would resolve this"
                    }
                  ],
                  "strategy_adjustments": ["adjustment1", "adjustment2"],
                  "red_flags": ["flag1", "flag2"],
                  "confidence_score": 0.82,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"]
                }
                """.formatted(research, persona, strategy);
    }
}
