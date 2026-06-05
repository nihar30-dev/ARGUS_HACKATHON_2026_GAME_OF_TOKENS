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

/**
 * Gemini-based agent (order 7).
 *
 * Synthesises ALL six prior agents' outputs into a complete meeting preparation package.
 * Reads the refined strategy from StrategyRefinementAgent as the authoritative strategy
 * (not the initial draft from EngagementStrategyAgent).
 *
 * Must NOT regenerate from scratch — must synthesise and reference what changed
 * due to objections, critic validation, and strategy refinement.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class FinalSynthesisAgent extends BaseAgent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()         { return "FinalSynthesisAgent"; }
    @Override public int    getOrder()        { return 7; }
    @Override public AgentType getAgentType() { return AgentType.GEMINI_BASED; }

    private static final List<String> ALL_SOURCES = List.of(
            "OrganizationResearchAgent", "StakeholderPersonaAgent",
            "EngagementStrategyAgent", "ObjectionPredictionAgent",
            "CriticValidatorAgent", "StrategyRefinementAgent");

    @Override
    public AgentResult execute(AgentContext context) {
        ALL_SOURCES.forEach(src -> addTrace(context, src, "INFLUENCE",
                "FinalSynthesisAgent synthesised output from " + src));
        addTrace(context, "CriticValidatorAgent", "CONFLICT_RESOLUTION",
                "FinalSynthesisAgent resolved all critic flags by incorporating the refined strategy");

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String raw = geminiService.generate(buildPrompt(context));
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
                ALL_SOURCES,
                usedGemini,
                "All 6 prior agents including StrategyRefinementAgent",
                "Complete meeting preparation package — executive brief, conversation flow, Q&A");

        context.putResult(getName(), result);
        return result;
    }

    private String buildPrompt(AgentContext context) {
        return """
                You are a senior business consultant. SYNTHESISE (do not regenerate) a complete meeting
                preparation package from the six specialist agents below.

                You MUST reference which recommendations changed due to objections, critic validation,
                and strategy refinement. Do NOT invent new content — only synthesise what the agents produced.

                1. Organization Research:
                %s

                2. Stakeholder Persona:
                %s

                3. Initial Engagement Strategy:
                %s

                4. Objection Predictions:
                %s

                5. Critic Validation (all issues that were flagged):
                %s

                6. Refined Strategy (AUTHORITATIVE — this supersedes the initial strategy):
                %s

                Return raw JSON only (no markdown):
                {
                  "agent": "FinalSynthesisAgent",
                  "executive_brief": "2-3 sentence summary referencing the refined positioning",
                  "meeting_objective": "specific goal from refined strategy",
                  "recommended_positioning": "revised_positioning from StrategyRefinementAgent",
                  "conversation_flow": [
                    {"phase": "Opening",           "duration": "5 min",  "approach": "description"},
                    {"phase": "Discovery",          "duration": "10 min", "approach": "description"},
                    {"phase": "Demonstration",      "duration": "15 min", "approach": "description"},
                    {"phase": "Objection Handling", "duration": "10 min", "approach": "description"},
                    {"phase": "Close",              "duration": "5 min",  "approach": "description"}
                  ],
                  "questions_to_ask": ["q1", "q2", "q3"],
                  "objections_and_responses": [
                    {"objection": "text", "response": "text", "risk_level": 0.9}
                  ],
                  "next_steps": ["step1", "step2", "step3"],
                  "refinements_applied": ["what changed due to critic feedback or objections"],
                  "readiness_score": 0.91,
                  "confidence_score": 0.91,
                  "overallConfidenceScore": 0.91,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent",
                                   "EngagementStrategyAgent", "ObjectionPredictionAgent",
                                   "CriticValidatorAgent", "StrategyRefinementAgent"]
                }
                """.formatted(
                getPreviousOutputJson(context, "OrganizationResearchAgent"),
                getPreviousOutputJson(context, "StakeholderPersonaAgent"),
                getPreviousOutputJson(context, "EngagementStrategyAgent"),
                getPreviousOutputJson(context, "ObjectionPredictionAgent"),
                getPreviousOutputJson(context, "CriticValidatorAgent"),
                getPreviousOutputJson(context, "StrategyRefinementAgent"));
    }
}
