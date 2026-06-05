package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentResult;
import com.argusoft.meetwise.agent.BaseAgent;
import com.argusoft.meetwise.agent.core.AgentType;
import com.argusoft.meetwise.service.FallbackDataService;
import com.argusoft.meetwise.service.LlmService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

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

    private final LlmService llmService;
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

        String ragContextText = formatRagContext(context);
        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String raw = llmService.generate(buildPrompt(context, ragContextText));
                if (isValidJson(raw)) {
                    outputJson = raw;
                    usedGemini = true;
                } else {
                    log.warn("[{}] LLM returned invalid JSON, using fallback", getName());
                    outputJson = fallbackDataService.loadFallback(getName());
                }
            } catch (Exception e) {
                log.warn("[{}] LLM call failed ({}), using fallback", getName(), e.getMessage());
                outputJson = fallbackDataService.loadFallback(getName());
            }
        }

        AgentResult result = withRagMetadata(
                success(outputJson,
                        extractConfidence(outputJson),
                        ALL_SOURCES,
                        usedGemini,
                        "All 6 prior agents including StrategyRefinementAgent",
                        "Complete meeting preparation package — executive brief, conversation flow, Q&A"),
                context,
                extractEvidenceGaps(outputJson));

        context.putResult(getName(), result);
        return result;
    }

    private String buildPrompt(AgentContext context, String ragContextText) {
        // Extract only the key fields from each agent to keep the prompt within token limits.
        // Full JSONs from 6 agents can exceed 3000+ tokens; summaries keep it under 1200.
        String orgSummary      = extractField(context, "OrganizationResearchAgent",
                                     "organization_summary", "industry_context", "possible_pain_points");
        String personaSummary  = extractField(context, "StakeholderPersonaAgent",
                                     "stakeholder_role", "decision_lens", "communication_style", "what_to_emphasize");
        String strategyGoal    = extractField(context, "EngagementStrategyAgent",
                                     "meeting_goal", "value_proposition", "key_messages");
        String objectionList   = extractField(context, "ObjectionPredictionAgent",
                                     "objections", "red_flags");
        String criticIssues    = extractField(context, "CriticValidatorAgent",
                                     "weak_assumptions", "contradictions", "recommended_revisions", "readiness_score");
        String refinedStrategy = extractField(context, "StrategyRefinementAgent",
                                     "revised_positioning", "revised_value_proposition",
                                     "revised_key_messages", "changes_made");

        return """
                You are a senior business consultant. Synthesise a meeting brief from the data below.
                Use ONLY the provided data. Resolve any conflicts using REFINED STRATEGY.
                Be concise — max 20 words per string value.

                ORGANIZATION: %s
                STAKEHOLDER: %s
                STRATEGY: %s
                OBJECTIONS: %s
                CRITIC FLAGS: %s
                REFINED STRATEGY: %s
                %s
                Return ONLY a raw JSON object. Do NOT wrap in markdown or code fences.
                {
                  "agent": "FinalSynthesisAgent",
                  "executive_brief": "2-sentence summary",
                  "meeting_objective": "one sentence goal",
                  "recommended_positioning": "one sentence from refined strategy",
                  "conversation_flow": [
                    {"phase": "Opening",    "approach": "brief approach"},
                    {"phase": "Discovery",  "approach": "brief approach"},
                    {"phase": "Close",      "approach": "brief approach"}
                  ],
                  "questions_to_ask": ["q1", "q2", "q3"],
                  "objections_and_responses": [
                    {"objection": "text", "response": "text", "risk_level": 0.9}
                  ],
                  "next_steps": ["step1", "step2", "step3"],
                  "refinements_applied": ["change1", "change2"],
                  "evidence_gaps": [],
                  "readiness_score": 0.91,
                  "confidence_score": 0.91,
                  "overallConfidenceScore": 0.91,
                  "influencedBy": ["OrganizationResearchAgent","StakeholderPersonaAgent",
                                   "EngagementStrategyAgent","ObjectionPredictionAgent",
                                   "CriticValidatorAgent","StrategyRefinementAgent"]
                }
                """.formatted(orgSummary, personaSummary, strategyGoal,
                              objectionList, criticIssues, refinedStrategy, ragContextText);
    }

    /**
     * Extracts only the specified keys from a prior agent's JSON output.
     * Keeps the prompt compact so the response fits within 2048 output tokens.
     */
    private String extractField(AgentContext context, String agentName, String... keys) {
        Map<String, Object> output = getPreviousOutput(context, agentName);
        if (output.isEmpty()) return "(no data)";
        StringBuilder sb = new StringBuilder("{");
        for (String key : keys) {
            Object val = output.get(key);
            if (val != null) {
                try {
                    sb.append("\"").append(key).append("\":").append(objectMapper.writeValueAsString(val)).append(",");
                } catch (Exception ignored) {}
            }
        }
        if (sb.charAt(sb.length() - 1) == ',') sb.setLength(sb.length() - 1);
        sb.append("}");
        return sb.toString();
    }
}
