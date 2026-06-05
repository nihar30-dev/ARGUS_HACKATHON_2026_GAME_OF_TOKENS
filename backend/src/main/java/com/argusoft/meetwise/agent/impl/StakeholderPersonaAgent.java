package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentOutput;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Rule-based agent — no Gemini call.
 * Derives stakeholder persona from role title using deterministic lookup rules.
 */
@Component
@Slf4j
public class StakeholderPersonaAgent implements Agent {

    @Override
    public String getName() { return "StakeholderPersonaAgent"; }

    @Override
    public int getOrder() { return 2; }

    @Override
    public AgentOutput execute(AgentContext context) {
        String role = context.getMeetingRequest().getStakeholderRole();
        String roleUpper = role.toUpperCase();

        String communicationStyle;
        String decisionLens;
        List<String> priorities;
        List<String> talkingPoints;

        if (roleUpper.contains("CTO") || roleUpper.contains("CHIEF TECHNOLOGY") || roleUpper.contains("TECH")) {
            communicationStyle = "technical";
            decisionLens = "technical_feasibility";
            priorities = List.of("Technical scalability", "Integration complexity", "Security and compliance", "Developer experience");
            talkingPoints = List.of("API architecture", "Integration timeline", "Data sovereignty options", "Vendor support SLA");
        } else if (roleUpper.contains("CFO") || roleUpper.contains("CHIEF FINANCIAL") || roleUpper.contains("FINANCE")) {
            communicationStyle = "analytical";
            decisionLens = "financial_impact";
            priorities = List.of("ROI and payback period", "Total cost of ownership", "Budget fit", "Risk mitigation");
            talkingPoints = List.of("Cost savings projection", "Revenue impact", "Competitive pricing", "Budget alignment");
        } else if (roleUpper.contains("CEO") || roleUpper.contains("CHIEF EXECUTIVE") || roleUpper.contains("MANAGING DIRECTOR")) {
            communicationStyle = "strategic";
            decisionLens = "strategic_value";
            priorities = List.of("Competitive advantage", "Market positioning", "Long-term growth", "Operational efficiency");
            talkingPoints = List.of("Market opportunity", "Competitive differentiation", "Growth trajectory", "Quick wins");
        } else if (roleUpper.contains("VP") || roleUpper.contains("VICE PRESIDENT") || roleUpper.contains("HEAD OF")) {
            communicationStyle = "results-oriented";
            decisionLens = "operational_impact";
            priorities = List.of("Team productivity", "Goal achievement", "Process improvement", "Reporting clarity");
            talkingPoints = List.of("Productivity metrics", "Process automation", "Measurable KPIs", "Team enablement");
        } else if (roleUpper.contains("COO") || roleUpper.contains("OPERATIONS")) {
            communicationStyle = "process-driven";
            decisionLens = "operational_efficiency";
            priorities = List.of("Process standardisation", "Operational costs", "Scalability", "Change management");
            talkingPoints = List.of("Implementation speed", "Change management support", "Process integration", "Efficiency gains");
        } else {
            communicationStyle = "collaborative";
            decisionLens = "practical_value";
            priorities = List.of("Ease of use", "Team buy-in", "Practical outcomes", "Support availability");
            talkingPoints = List.of("Ease of implementation", "Training and onboarding", "Ongoing support", "Peer references");
        }

        String outputJson = """
                {
                  "agent": "StakeholderPersonaAgent",
                  "stakeholderRole": "%s",
                  "priorities": %s,
                  "communicationStyle": "%s",
                  "decisionLens": "%s",
                  "talkingPoints": %s,
                  "confidenceScore": 1.0,
                  "influencedBy": ["OrganizationResearchAgent"]
                }
                """.formatted(
                role,
                toJsonArray(priorities),
                communicationStyle,
                decisionLens,
                toJsonArray(talkingPoints)
        );

        log.info("[{}] Built persona for role '{}': style={}, lens={}", getName(), role, communicationStyle, decisionLens);

        return AgentOutput.builder()
                .agentName(getName())
                .outputJson(outputJson.strip())
                .confidenceScore(1.0)
                .influencedBy(List.of("OrganizationResearchAgent"))
                .usedGemini(false)
                .inputSummary("Role: " + role)
                .outputSummary(communicationStyle + " communicator, " + decisionLens + " decision lens")
                .build();
    }

    private String toJsonArray(List<String> items) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            sb.append("\"").append(items.get(i).replace("\"", "\\\"")).append("\"");
            if (i < items.size() - 1) sb.append(", ");
        }
        sb.append("]");
        return sb.toString();
    }
}
