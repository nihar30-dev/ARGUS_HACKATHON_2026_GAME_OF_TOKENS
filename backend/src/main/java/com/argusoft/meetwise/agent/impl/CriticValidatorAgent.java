package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentOutput;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Rule-based agent — no Gemini call.
 * Validates all prior agent outputs for consistency, completeness, and confidence.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CriticValidatorAgent implements Agent {

    private final ObjectMapper objectMapper;

    @Override
    public String getName() { return "CriticValidatorAgent"; }

    @Override
    public int getOrder() { return 5; }

    @Override
    public AgentOutput execute(AgentContext context) {
        List<Map<String, Object>> issues = new ArrayList<>();
        List<String> improvements = new ArrayList<>();

        Map<String, Object> research  = parse(context.getOutput("OrganizationResearchAgent"));
        Map<String, Object> persona   = parse(context.getOutput("StakeholderPersonaAgent"));
        Map<String, Object> strategy  = parse(context.getOutput("EngagementStrategyAgent"));
        Map<String, Object> objection = parse(context.getOutput("ObjectionPredictionAgent"));

        checkLowConfidence("OrganizationResearchAgent", research, issues, improvements);
        checkLowConfidence("EngagementStrategyAgent", strategy, issues, improvements);
        checkLowConfidence("ObjectionPredictionAgent", objection, issues, improvements);

        checkRequiredListField("OrganizationResearchAgent", research, "painPoints", issues, improvements);
        checkRequiredListField("EngagementStrategyAgent", strategy, "keyMessages", issues, improvements);
        checkRequiredListField("ObjectionPredictionAgent", objection, "objections", issues, improvements);

        checkObjectionCoveredByStrategy(strategy, objection, issues, improvements);

        double overallConfidence = computeOverall(research, strategy, objection);
        boolean passed = issues.stream().noneMatch(i -> "error".equals(i.get("severity")));

        String outputJson = buildOutputJson(passed, issues, improvements, overallConfidence);

        log.info("[{}] Validation: passed={}, issues={}, improvements={}", getName(), passed, issues.size(), improvements.size());

        return AgentOutput.builder()
                .agentName(getName())
                .outputJson(outputJson)
                .confidenceScore(1.0)
                .influencedBy(List.of("OrganizationResearchAgent", "StakeholderPersonaAgent",
                        "EngagementStrategyAgent", "ObjectionPredictionAgent"))
                .usedGemini(false)
                .inputSummary("Outputs from all 4 prior agents")
                .outputSummary("Found " + issues.size() + " issues, " + improvements.size() + " improvements")
                .build();
    }

    private void checkLowConfidence(String agentName, Map<String, Object> output,
                                    List<Map<String, Object>> issues, List<String> improvements) {
        Object raw = output.get("confidenceScore");
        if (raw == null) return;
        double score = ((Number) raw).doubleValue();
        if (score < 0.3) {
            issues.add(Map.of("agentName", agentName, "severity", "error",
                    "issue", agentName + " has very low confidence (" + score + ") — output may be unreliable"));
            improvements.add("Re-run " + agentName + " with more specific input data");
        } else if (score < 0.6) {
            issues.add(Map.of("agentName", agentName, "severity", "warning",
                    "issue", agentName + " has moderate confidence (" + score + ")"));
            improvements.add("Consider enriching input for " + agentName);
        }
    }

    private void checkRequiredListField(String agentName, Map<String, Object> output,
                                        String field, List<Map<String, Object>> issues, List<String> improvements) {
        Object val = output.get(field);
        if (val == null || (val instanceof List<?> list && list.isEmpty())) {
            issues.add(Map.of("agentName", agentName, "severity", "error",
                    "issue", "Required field '" + field + "' is missing or empty in " + agentName));
            improvements.add("Ensure " + agentName + " produces a non-empty '" + field + "' list");
        }
    }

    private void checkObjectionCoveredByStrategy(Map<String, Object> strategy,
                                                  Map<String, Object> objection,
                                                  List<Map<String, Object>> issues,
                                                  List<String> improvements) {
        Object objList = objection.get("objections");
        if (!(objList instanceof List<?> objections) || objections.isEmpty()) return;

        Object keyMsgs = strategy.get("keyMessages");
        if (!(keyMsgs instanceof List<?> messages) || messages.isEmpty()) return;

        String firstObjText = "";
        if (objections.get(0) instanceof Map<?, ?> firstObj) {
            Object likelihood = firstObj.get("likelihood");
            if (likelihood != null && ((Number) likelihood).doubleValue() >= 0.85) {
                firstObjText = String.valueOf(firstObj.get("objection"));
            }
        }

        if (!firstObjText.isBlank()) {
            boolean covered = false;

            for (Object messageObj : messages) {
                String m = String.valueOf(messageObj);

                if (firstObjText.length() > 10 && m.length() > 5) {

                    String subText = firstObjText.substring(
                            0,
                            Math.min(20, firstObjText.length())
                    ).toLowerCase();

                    long matchCount = 0;

                    for (char c : subText.toCharArray()) {
                        if (m.toLowerCase().indexOf(c) >= 0) {
                            matchCount++;
                        }
                    }

                    if (matchCount > 5) {
                        covered = true;
                        break;
                    }
                }
            }
            if (!covered) {
                issues.add(Map.of("agentName", "EngagementStrategyAgent", "severity", "warning",
                        "issue", "Highest-likelihood objection is not directly addressed in strategy key messages"));
                improvements.add("Add a direct counter to the top objection in the strategy's key messages or opening approach");
            }
        }
    }

    @SafeVarargs
    private double computeOverall(Map<String, Object>... outputs) {
        double sum = 0;
        int count = 0;
        for (Map<String, Object> output : outputs) {
            Object raw = output.get("confidenceScore");
            if (raw != null) {
                sum += ((Number) raw).doubleValue();
                count++;
            }
        }
        return count == 0 ? 0.5 : sum / count;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> parse(String json) {
        try {
            return objectMapper.readValue(json, Map.class);
        } catch (Exception e) {
            log.warn("[{}] Failed to parse agent output JSON", getName());
            return Map.of();
        }
    }

    private String buildOutputJson(boolean passed, List<Map<String, Object>> issues,
                                   List<String> improvements, double overallConfidence) {
        try {
            Map<String, Object> output = new java.util.LinkedHashMap<>();
            output.put("agent", "CriticValidatorAgent");
            output.put("validationPassed", passed);
            output.put("issues", issues);
            output.put("improvements", improvements);
            output.put("overallConfidenceScore", Math.round(overallConfidence * 1000.0) / 1000.0);
            output.put("confidenceScore", 1.0);
            output.put("influencedBy", List.of("OrganizationResearchAgent", "StakeholderPersonaAgent",
                    "EngagementStrategyAgent", "ObjectionPredictionAgent"));
            return objectMapper.writeValueAsString(output);
        } catch (Exception e) {
            return "{\"agent\":\"CriticValidatorAgent\",\"validationPassed\":true,\"confidenceScore\":1.0,\"influencedBy\":[]}";
        }
    }
}
