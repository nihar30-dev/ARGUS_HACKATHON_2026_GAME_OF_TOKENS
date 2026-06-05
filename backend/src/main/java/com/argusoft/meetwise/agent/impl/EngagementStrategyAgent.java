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

/**
 * Gemini-based agent (order 3).
 * Builds the initial meeting engagement strategy from Research + Persona outputs.
 * Refinement is handled by the dedicated StrategyRefinementAgent (order 6).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class EngagementStrategyAgent extends BaseAgent {

    private final LlmService llmService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()         { return "EngagementStrategyAgent"; }
    @Override public int    getOrder()        { return 3; }
    @Override public AgentType getAgentType() { return AgentType.GEMINI_BASED; }

    @Override
    public AgentResult execute(AgentContext context) {
        // Use compact summaries — passing full JSONs inflates prompt size and causes truncation
        String researchJson = compactSummary(context, "OrganizationResearchAgent",
                "organization_summary", "industry_context", "possible_pain_points", "solution_fit");
        String personaJson  = compactSummary(context, "StakeholderPersonaAgent",
                "stakeholder_role", "decision_lens", "communication_style", "what_to_emphasize");
        String offering     = context.getMeetingRequest().getOfferingDescription();

        addTrace(context, "OrganizationResearchAgent", "INFLUENCE",
                "EngagementStrategyAgent used organization pain points and priorities to build positioning");
        addTrace(context, "StakeholderPersonaAgent", "INFLUENCE",
                "EngagementStrategyAgent tailored strategy to stakeholder decision lens and communication style");

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
        } else {
            try {
                String raw = llmService.generate(buildPrompt(researchJson, personaJson, offering));
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
                List.of("OrganizationResearchAgent", "StakeholderPersonaAgent"),
                usedGemini,
                "Research + Persona for " + context.getMeetingRequest().getOrganizationName(),
                "Initial meeting strategy with positioning and value proposition");

        context.putResult(getName(), result);
        log.info("[{}] Strategy built, confidence={}", getName(), result.getConfidenceScore());
        return result;
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

                Return ONLY a raw JSON object. Do NOT wrap in markdown or code fences.
                {
                  "agent": "EngagementStrategyAgent",
                  "meeting_goal": "specific goal for this meeting",
                  "primary_positioning": "how to position the offering for this stakeholder",
                  "value_proposition": "tailored 1-2 sentence value proposition with specific differentiators",
                  "partnership_angles": ["angle1", "angle2"],
                  "success_criteria": ["criterion1", "criterion2", "criterion3"],
                  "recommended_next_step": "the single most important next action to propose",
                  "key_messages": ["message1", "message2", "message3"],
                  "confidence_score": 0.88,
                  "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent"]
                }
                """.formatted(research, persona, offering);
    }
}
