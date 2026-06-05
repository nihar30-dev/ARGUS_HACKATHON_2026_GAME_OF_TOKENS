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

@Component
@RequiredArgsConstructor
@Slf4j
public class ObjectionPredictionAgent extends BaseAgent {

    private final LlmService llmService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()         { return "ObjectionPredictionAgent"; }
    @Override public int    getOrder()        { return 4; }
    @Override public AgentType getAgentType() { return AgentType.GEMINI_BASED; }

    @Override
    public AgentResult execute(AgentContext context) {
        // Use compact summaries — passing full JSONs inflates prompt size and causes truncation
        String researchJson = compactSummary(context, "OrganizationResearchAgent",
                "organization_summary", "possible_pain_points", "solution_fit");
        String personaJson  = compactSummary(context, "StakeholderPersonaAgent",
                "stakeholder_role", "decision_lens", "communication_style");
        String strategyJson = compactSummary(context, "EngagementStrategyAgent",
                "meeting_goal", "value_proposition", "key_messages", "primary_positioning");

        addTrace(context, "OrganizationResearchAgent", "INFLUENCE",
                "ObjectionPredictionAgent used org pain points to anticipate resistance");
        addTrace(context, "StakeholderPersonaAgent", "INFLUENCE",
                "ObjectionPredictionAgent predicted objections aligned with stakeholder decision lens");
        addTrace(context, "EngagementStrategyAgent", "INFLUENCE",
                "ObjectionPredictionAgent challenged the proposed strategy by stress-testing its key messages");

        String ragContextText = formatRagContext(context);
        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String raw = llmService.generate(buildPrompt(researchJson, personaJson, strategyJson, ragContextText));
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
                        List.of("OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"),
                        usedGemini,
                        "Research + Persona + Strategy outputs",
                        "Top objections with counter-responses and risks"),
                context,
                extractEvidenceGaps(outputJson));

        context.putResult(getName(), result);
        return result;
    }

    private String buildPrompt(String research, String persona, String strategy, String ragContext) {
        return """
               You are a skeptical executive reviewing this meeting strategy.

                Do not agree automatically.
                Identify realistic risks, missing evidence, weak assumptions, budget concerns, adoption challenges, integration risks, and stakeholder objections.

                Requirements:
                - Generate 3-5 unique objections.
                - Focus on high-impact executive concerns.
                - Keep responses concise.
                - Avoid repetition.
                - Use organization, persona, and strategy context.
                - Use retrieved knowledge to ground objections in known patterns.
                - Return JSON only.

                Organization Research:
                %s

                Stakeholder Persona:
                %s

                Proposed Engagement Strategy:
                %s
                %s
                Return ONLY a raw JSON object. Do NOT wrap in markdown or code fences.

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
                "evidence_gaps": [],
                "confidence_score": 0.82,
                "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"]
                }
                """.formatted(research, persona, strategy, ragContext);
    }
}
