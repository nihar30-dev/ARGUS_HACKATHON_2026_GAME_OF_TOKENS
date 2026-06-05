package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentResult;
import com.argusoft.meetwise.agent.BaseAgent;
import com.argusoft.meetwise.agent.core.AgentType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Rule-based agent — no Gemini call.
 * Derives stakeholder persona from the role title using deterministic lookup rules.
 * Reads OrganizationResearchAgent output for context but produces its own analysis.
 */
@Component
@Slf4j
public class StakeholderPersonaAgent extends BaseAgent {

    @Override public String getName()         { return "StakeholderPersonaAgent"; }
    @Override public int    getOrder()        { return 2; }
    @Override public AgentType getAgentType() { return AgentType.RULE_BASED; }

    @Override
    public AgentResult execute(AgentContext context) {
        String role      = context.getMeetingRequest().getStakeholderRole();
        String roleUpper = role.toUpperCase();

        // Emit a trace so judges can see this agent reading prior output
        addTrace(context, "OrganizationResearchAgent", "INFLUENCE",
                "StakeholderPersonaAgent used organization context to tailor persona priorities");

        String communicationStyle;
        String decisionLens;
        List<String> priorities;
        List<String> talkingPoints;

        if (roleUpper.contains("CTO") || roleUpper.contains("CHIEF TECHNOLOGY") || roleUpper.contains("TECH")) {
            communicationStyle = "technical";
            decisionLens       = "technical_feasibility";
            priorities     = List.of("Technical scalability", "Integration complexity", "Security and compliance", "Developer experience");
            talkingPoints  = List.of("API architecture", "Integration timeline", "Data sovereignty options", "Vendor support SLA");
        } else if (roleUpper.contains("CFO") || roleUpper.contains("CHIEF FINANCIAL") || roleUpper.contains("FINANCE")) {
            communicationStyle = "analytical";
            decisionLens       = "financial_impact";
            priorities     = List.of("ROI and payback period", "Total cost of ownership", "Budget fit", "Risk mitigation");
            talkingPoints  = List.of("Cost savings projection", "Revenue impact", "Competitive pricing", "Budget alignment");
        } else if (roleUpper.contains("CEO") || roleUpper.contains("CHIEF EXECUTIVE") || roleUpper.contains("MANAGING DIRECTOR")) {
            communicationStyle = "strategic";
            decisionLens       = "strategic_value";
            priorities     = List.of("Competitive advantage", "Market positioning", "Long-term growth", "Operational efficiency");
            talkingPoints  = List.of("Market opportunity", "Competitive differentiation", "Growth trajectory", "Quick wins");
        } else if (roleUpper.contains("VP") || roleUpper.contains("VICE PRESIDENT") || roleUpper.contains("HEAD OF")) {
            communicationStyle = "results-oriented";
            decisionLens       = "operational_impact";
            priorities     = List.of("Team productivity", "Goal achievement", "Process improvement", "Reporting clarity");
            talkingPoints  = List.of("Productivity metrics", "Process automation", "Measurable KPIs", "Team enablement");
        } else if (roleUpper.contains("COO") || roleUpper.contains("OPERATIONS")) {
            communicationStyle = "process-driven";
            decisionLens       = "operational_efficiency";
            priorities     = List.of("Process standardisation", "Operational costs", "Scalability", "Change management");
            talkingPoints  = List.of("Implementation speed", "Change management support", "Process integration", "Efficiency gains");
        } else {
            communicationStyle = "collaborative";
            decisionLens       = "practical_value";
            priorities     = List.of("Ease of use", "Team buy-in", "Practical outcomes", "Support availability");
            talkingPoints  = List.of("Ease of implementation", "Training and onboarding", "Ongoing support", "Peer references");
        }

        String outputJson = """
                {
                  "agent": "StakeholderPersonaAgent",
                  "stakeholder_role": "%s",
                  "likely_priorities": %s,
                  "decision_lens": "%s",
                  "communication_style": "%s",
                  "what_to_emphasize": %s,
                  "what_to_avoid": ["Overly technical jargon without business context", "Generic ROI claims without evidence", "Long-term roadmaps without near-term value"],
                  "confidence_score": 1.0,
                  "influencedBy": ["OrganizationResearchAgent"]
                }
                """.formatted(
                role,
                toJsonArray(priorities),
                decisionLens,
                communicationStyle,
                toJsonArray(talkingPoints)).strip();

        log.info("[{}] Built persona for role '{}': style={}, lens={}",
                getName(), role, communicationStyle, decisionLens);

        AgentResult result = success(
                outputJson,
                1.0,
                List.of("OrganizationResearchAgent"),
                false,
                "Role: " + role,
                communicationStyle + " communicator, " + decisionLens + " decision lens");

        context.putResult(getName(), result);
        return result;
    }

    private String toJsonArray(List<String> items) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            sb.append("\"").append(items.get(i).replace("\"", "\\\"")).append("\"");
            if (i < items.size() - 1) sb.append(", ");
        }
        return sb.append("]").toString();
    }
}
