package com.argusoft.meetwise.agent;

import com.argusoft.meetwise.agent.core.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Abstract base for all MeetWise agents.
 *
 * Provides:
 *  - Factories for SUCCESS / FALLBACK / FAILED AgentResult
 *  - Context read helpers (raw JSON + deserialized Map)
 *  - Trace message recording
 *  - Influence / validation-feedback / conflict-resolution record builders
 *  - Shared extractConfidence() so Gemini agents don't duplicate parsing logic
 */
@Slf4j
public abstract class BaseAgent implements Agent {

    protected final ObjectMapper objectMapper = new ObjectMapper();

    // -----------------------------------------------------------------------
    // Result factories
    // -----------------------------------------------------------------------

    protected AgentResult success(String outputJson,
                                  double confidence,
                                  List<String> influencedBy,
                                  boolean usedGemini,
                                  String inputSummary,
                                  String outputSummary) {
        return AgentResult.builder()
                .agentName(getName())
                .agentType(getAgentType())
                .status(AgentStatus.SUCCESS)
                .outputJson(outputJson)
                .output(parseOutputMap(outputJson))
                .confidenceScore(confidence)
                .influencedBy(safe(influencedBy))
                .influences(List.of())
                .assumptions(List.of())
                .validationFeedback(List.of())
                .conflictResolutionNotes(List.of())
                .usedGemini(usedGemini)
                .inputSummary(inputSummary)
                .outputSummary(outputSummary)
                .influenceSummary(buildInfluenceSummary(influencedBy))
                .traceSummary(getName() + " completed with confidence=" + confidence)
                .build();
    }

    protected AgentResult fallback(String fallbackJson,
                                   String reason,
                                   List<String> influencedBy,
                                   String inputSummary) {
        return AgentResult.builder()
                .agentName(getName())
                .agentType(getAgentType())
                .status(AgentStatus.FALLBACK)
                .outputJson(fallbackJson)
                .output(parseOutputMap(fallbackJson))
                .confidenceScore(0.6)
                .influencedBy(safe(influencedBy))
                .influences(List.of())
                .assumptions(List.of())
                .validationFeedback(List.of())
                .conflictResolutionNotes(List.of())
                .usedGemini(false)
                .inputSummary(inputSummary)
                .outputSummary("Fallback data used — " + reason)
                .influenceSummary(buildInfluenceSummary(influencedBy))
                .traceSummary(getName() + " used fallback: " + reason)
                .build();
    }

    protected AgentResult failed(String errorMessage,
                                 List<String> influencedBy) {
        return AgentResult.builder()
                .agentName(getName())
                .agentType(getAgentType())
                .status(AgentStatus.FAILED)
                .outputJson("{}")
                .output(Map.of())
                .confidenceScore(0.0)
                .influencedBy(safe(influencedBy))
                .influences(List.of())
                .assumptions(List.of())
                .validationFeedback(List.of())
                .conflictResolutionNotes(List.of())
                .usedGemini(false)
                .errorMessage(errorMessage)
                .traceSummary(getName() + " FAILED: " + errorMessage)
                .build();
    }

    // -----------------------------------------------------------------------
    // Context read helpers
    // -----------------------------------------------------------------------

    protected String getPreviousOutputJson(AgentContext context, String agentName) {
        return context.getOutput(agentName);
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> getPreviousOutput(AgentContext context, String agentName) {
        String json = context.getOutput(agentName);
        if (json == null || json.isBlank() || "{}".equals(json)) return Map.of();
        try {
            return objectMapper.readValue(json, Map.class);
        } catch (Exception e) {
            log.warn("[{}] Could not parse output from {}", getName(), agentName);
            return Map.of();
        }
    }

    // -----------------------------------------------------------------------
    // Trace helpers
    // -----------------------------------------------------------------------

    protected void addTrace(AgentContext context,
                            String sourceAgent,
                            String messageType,
                            String content) {
        context.addTraceMessage(AgentTraceMessage.builder()
                .sourceAgent(sourceAgent)
                .targetAgent(getName())
                .messageType(messageType)
                .content(content)
                .build());
    }

    // -----------------------------------------------------------------------
    // Influence / validation / conflict record builders
    // -----------------------------------------------------------------------

    protected InfluenceRecord recordInfluence(String sourceAgent,
                                              String influenceType,
                                              String description) {
        return InfluenceRecord.builder()
                .sourceAgent(sourceAgent)
                .targetAgent(getName())
                .influenceType(influenceType)
                .description(description)
                .build();
    }

    protected ValidationFeedback recordValidationFeedback(String fromAgent,
                                                          String severity,
                                                          String issue,
                                                          String suggestion) {
        return ValidationFeedback.builder()
                .fromAgent(fromAgent)
                .severity(severity)
                .issue(issue)
                .suggestion(suggestion)
                .build();
    }

    protected ConflictResolutionNote recordConflictResolution(List<String> conflictingAgents,
                                                              String conflictDescription,
                                                              String resolution) {
        return ConflictResolutionNote.builder()
                .conflictingAgents(conflictingAgents)
                .conflictDescription(conflictDescription)
                .resolution(resolution)
                .resolvedBy(getName())
                .build();
    }

    // -----------------------------------------------------------------------
    // Confidence helpers
    // -----------------------------------------------------------------------

    /** Extracts confidenceScore / confidence_score from a raw JSON string. */
    protected double extractConfidence(String json) {
        for (String key : new String[]{"\"confidenceScore\"", "\"confidence_score\"", "\"readiness_score\""}) {
            try {
                int idx = json.indexOf(key);
                if (idx == -1) continue;
                int colon = json.indexOf(":", idx);
                int comma = json.indexOf(",", colon);
                int brace = json.indexOf("}", colon);
                int end = (comma == -1) ? brace : (brace == -1) ? comma : Math.min(comma, brace);
                return Double.parseDouble(json.substring(colon + 1, end).trim());
            } catch (Exception ignored) {}
        }
        return 0.5;
    }

    protected boolean meetsConfidenceThreshold(AgentResult result, double threshold) {
        return result != null && result.getConfidenceScore() >= threshold;
    }

    /** Returns true when json is non-null, non-blank, and parses without error. */
    protected boolean isValidJson(String json) {
        if (json == null || json.isBlank()) return false;
        try {
            objectMapper.readTree(json);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Extracts only the specified keys from a prior agent's output as a compact JSON string.
     * Use this instead of passing full raw JSONs in prompts — keeps prompts small so
     * Gemini responses fit within the token limit and don't get truncated.
     */
    protected String compactSummary(AgentContext context, String agentName, String... keys) {
        Map<String, Object> output = getPreviousOutput(context, agentName);
        if (output.isEmpty()) return "{}";
        StringBuilder sb = new StringBuilder("{");
        for (String key : keys) {
            Object val = output.get(key);
            if (val != null) {
                try {
                    sb.append("\"").append(key).append("\":")
                      .append(objectMapper.writeValueAsString(val)).append(",");
                } catch (Exception ignored) {}
            }
        }
        if (sb.length() > 1 && sb.charAt(sb.length() - 1) == ',') sb.setLength(sb.length() - 1);
        return sb.append("}").toString();
    }

    // -----------------------------------------------------------------------
    // Private utilities
    // -----------------------------------------------------------------------

    private String buildInfluenceSummary(List<String> influencedBy) {
        if (influencedBy == null || influencedBy.isEmpty())
            return getName() + " generated initial output independently";
        return getName() + " was shaped by: " + String.join(", ", influencedBy);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> parseOutputMap(String json) {
        if (json == null || json.isBlank() || "{}".equals(json)) return Map.of();
        try {
            return objectMapper.readValue(json, Map.class);
        } catch (Exception e) {
            return Map.of();
        }
    }

    private List<String> safe(List<String> list) {
        return list != null ? list : Collections.emptyList();
    }
}
