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
public class OrganizationResearchAgent extends BaseAgent {

    private final GeminiService geminiService;
    private final FallbackDataService fallbackDataService;

    @Value("${app.demo-mode:false}")
    private boolean demoMode;

    @Override public String getName()       { return "OrganizationResearchAgent"; }
    @Override public int    getOrder()      { return 1; }
    @Override public AgentType getAgentType() { return AgentType.GEMINI_BASED; }

    @Override
    public AgentResult execute(AgentContext context) {
        var meeting = context.getMeetingRequest();
        String inputSummary = "Organization: " + meeting.getOrganizationName()
                + " | Objective: " + meeting.getMeetingObjective();

        String outputJson;
        boolean usedGemini = false;

        if (demoMode) {
            outputJson = fallbackDataService.loadFallback(getName());
            log.info("[{}] Demo mode — loaded fallback JSON", getName());
        } else {
            try {
                String raw = geminiService.generate(
                        buildPrompt(meeting.getOrganizationName(),
                                meeting.getMeetingObjective(),
                                meeting.getOfferingDescription()));
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
                List.of(),
                usedGemini,
                inputSummary,
                "Organization analysis for " + meeting.getOrganizationName());

        context.putResult(getName(), result);
        return result;
    }

    private String buildPrompt(String orgName, String objective, String offering) {
        return """
                You are an expert business intelligence analyst.
                Analyze the following organization for a meeting preparation context.

                Organization: %s
                Meeting Objective: %s
                Our Offering: %s

                Return raw JSON only (no markdown):
                {
                  "agent": "OrganizationResearchAgent",
                  "organization_summary": "2-3 sentence summary",
                  "likely_priorities": ["priority1", "priority2", "priority3"],
                  "digital_health_relevance": "how digital health applies to this org",
                  "possible_pain_points": ["pain1", "pain2", "pain3"],
                  "partnership_fit": ["opportunity1", "opportunity2"],
                  "evidence_gaps": ["gap1"],
                  "confidence_score": 0.85,
                  "influencedBy": []
                }
                """.formatted(orgName, objective, offering);
    }
}
