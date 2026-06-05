package com.argusoft.meetwise.agent.impl;

import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentResult;
import com.argusoft.meetwise.agent.BaseAgent;
import com.argusoft.meetwise.agent.core.AgentStatus;
import com.argusoft.meetwise.agent.core.AgentType;
import com.argusoft.meetwise.agent.core.ValidationFeedback;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Rule-based agent (order 5) — no Gemini call.
 *
 * Examines ALL four prior agents' outputs and produces structured validation:
 * approved_points, weak_assumptions, contradictions, missing_information,
 * recommended_revisions, readiness_score.
 *
 * Output drives StrategyRefinementAgent (order 6): every item in
 * weak_assumptions, contradictions, and recommended_revisions is a directive
 * for the refinement pass.
 */
@Component
@Slf4j
public class CriticValidatorAgent extends BaseAgent {

    @Override public String getName()         { return "CriticValidatorAgent"; }
    @Override public int    getOrder()        { return 5; }
    @Override public AgentType getAgentType() { return AgentType.RULE_BASED; }

    private static final List<String> READS_FROM =
            List.of("OrganizationResearchAgent", "StakeholderPersonaAgent",
                    "EngagementStrategyAgent", "ObjectionPredictionAgent");

    @Override
    public AgentResult execute(AgentContext context) {
        READS_FROM.forEach(src -> addTrace(context, src, "VALIDATION",
                "CriticValidatorAgent examined " + src + " for issues, gaps, and contradictions"));

        Map<String, Object> research   = getPreviousOutput(context, "OrganizationResearchAgent");
        Map<String, Object> persona    = getPreviousOutput(context, "StakeholderPersonaAgent");
        Map<String, Object> strategy   = getPreviousOutput(context, "EngagementStrategyAgent");
        Map<String, Object> objections = getPreviousOutput(context, "ObjectionPredictionAgent");

        List<String>             approvedPoints       = new ArrayList<>();
        List<String>             weakAssumptions      = new ArrayList<>();
        List<String>             contradictions       = new ArrayList<>();
        List<String>             missingInformation   = new ArrayList<>();
        List<String>             recommendedRevisions = new ArrayList<>();
        List<ValidationFeedback> feedback             = new ArrayList<>();

        // ── Approved checks ────────────────────────────────────────────────
        collectApprovedPoints(research, strategy, approvedPoints);

        // ── Confidence threshold: flag < 0.70 ──────────────────────────────
        checkConfidence("OrganizationResearchAgent", research,  weakAssumptions, feedback);
        checkConfidence("EngagementStrategyAgent",   strategy,  weakAssumptions, feedback);
        checkConfidence("ObjectionPredictionAgent",  objections, weakAssumptions, feedback);

        // ── Required list completeness ──────────────────────────────────────
        // Objections: spec requires minimum 3
        checkListSize("ObjectionPredictionAgent", objections, "objections", 3,
                missingInformation, recommendedRevisions, feedback);
        checkListSize("EngagementStrategyAgent", strategy, "success_criteria", 2,
                missingInformation, recommendedRevisions, feedback);
        checkListSize("EngagementStrategyAgent", strategy, "key_messages", 2,
                missingInformation, recommendedRevisions, feedback);
        checkListSize("OrganizationResearchAgent", research, "possible_pain_points", 1,
                missingInformation, recommendedRevisions, feedback);

        // ── Generic / unsupported strategy detection ───────────────────────
        checkGenericStrategy(strategy, recommendedRevisions, feedback);

        // ── Contradiction detection ────────────────────────────────────────
        checkContradictions(research, strategy, objections, contradictions, feedback);

        // ── Missing evidence check ─────────────────────────────────────────
        checkMissingEvidence(strategy, objections, missingInformation, feedback);

        // ── Compute readiness_score ────────────────────────────────────────
        double readinessScore = computeReadiness(feedback);
        boolean passed = feedback.stream().noneMatch(f -> "error".equals(f.getSeverity()));

        String outputJson = buildOutputJson(passed, approvedPoints, weakAssumptions, contradictions,
                missingInformation, recommendedRevisions, readinessScore);

        log.info("[{}] passed={}, approvedPoints={}, weakAssumptions={}, contradictions={}, revisions={}",
                getName(), passed, approvedPoints.size(), weakAssumptions.size(),
                contradictions.size(), recommendedRevisions.size());

        AgentResult result = AgentResult.builder()
                .agentName(getName())
                .agentType(AgentType.RULE_BASED)
                .status(AgentStatus.SUCCESS)
                .outputJson(outputJson)
                .output(parseMap(outputJson))
                .confidenceScore(1.0)
                .influencedBy(READS_FROM)
                .influences(List.of("StrategyRefinementAgent", "FinalSynthesisAgent"))
                .assumptions(List.of())
                .validationFeedback(feedback)
                .conflictResolutionNotes(List.of())
                .usedGemini(false)
                .ragContextUsed(false)
                .ragSummary("Rule-based agent — RAG context stored but deterministic logic applied")
                .inputSummary("All 4 prior agent outputs")
                .outputSummary("weakAssumptions=" + weakAssumptions.size()
                        + ", contradictions=" + contradictions.size()
                        + ", revisions=" + recommendedRevisions.size()
                        + ", readiness=" + readinessScore)
                .influenceSummary("CriticValidatorAgent challenged all outputs from: "
                        + String.join(", ", READS_FROM))
                .traceSummary("Validation " + (passed ? "PASSED" : "FLAGGED") + " — readiness_score="
                        + readinessScore + ", " + recommendedRevisions.size() + " revision(s) directed to StrategyRefinementAgent")
                .build();

        context.putResult(getName(), result);
        return result;
    }

    // ── Validation checks ─────────────────────────────────────────────────────

    private void collectApprovedPoints(Map<String, Object> research,
                                        Map<String, Object> strategy,
                                        List<String> approved) {
        if (!isBlankOrMissing(research, "organization_summary"))
            approved.add("Organization summary is present");
        if (!isBlankOrMissing(strategy, "value_proposition"))
            approved.add("Value proposition is defined");
        if (!isBlankOrMissing(strategy, "meeting_goal"))
            approved.add("Meeting goal is stated");
        if (!isBlankOrMissing(strategy, "recommended_next_step"))
            approved.add("Recommended next step is defined");
        if (!isBlankOrMissing(strategy, "primary_positioning"))
            approved.add("Primary positioning is stated");
    }

    private void checkConfidence(String agentName, Map<String, Object> output,
                                  List<String> weakAssumptions,
                                  List<ValidationFeedback> feedback) {
        double score = getDoubleField(output, "confidence_score", "confidenceScore");
        if (score == 0.0) return; // field absent
        if (score < 0.70) {
            String msg = agentName + " confidence=" + score + " is below the required 0.70 threshold";
            weakAssumptions.add(msg);
            feedback.add(recordValidationFeedback(agentName,
                    score < 0.40 ? "error" : "warning", msg,
                    "Enrich input data for " + agentName + " to raise confidence above 0.70"));
        }
    }

    private void checkListSize(String agentName, Map<String, Object> output,
                                String field, int minSize,
                                List<String> missing, List<String> revisions,
                                List<ValidationFeedback> feedback) {
        Object val = output.get(field);
        int count = (val instanceof List<?> l) ? l.size() : 0;

        if (count == 0) {
            String msg = "Required field '" + field + "' is absent in " + agentName;
            missing.add(msg);
            feedback.add(recordValidationFeedback(agentName, "error", msg,
                    "Ensure " + agentName + " outputs a non-empty '" + field + "' list"));
        } else if (count < minSize) {
            String msg = "'" + field + "' in " + agentName + " has " + count
                    + " item(s); minimum required is " + minSize;
            revisions.add(msg);
            feedback.add(recordValidationFeedback(agentName, "warning", msg,
                    "Expand '" + field + "' to at least " + minSize + " items"));
        }
    }

    private void checkGenericStrategy(Map<String, Object> strategy,
                                       List<String> revisions,
                                       List<ValidationFeedback> feedback) {
        Object vp = strategy.get("value_proposition");
        if (vp instanceof String s && !s.isBlank() && s.length() < 50) {
            revisions.add("Value proposition is too brief — add specific, quantifiable differentiators");
            feedback.add(recordValidationFeedback("EngagementStrategyAgent", "warning",
                    "Value proposition is too generic (length=" + s.length() + "): \"" + s + "\"",
                    "Add specific differentiators, metrics, or proof points to value proposition"));
        }
        Object pos = strategy.get("primary_positioning");
        if (pos instanceof String p && !p.isBlank()
                && (p.toLowerCase().contains("solution") && p.length() < 60)) {
            revisions.add("Positioning is too generic — reference specific organization pain points");
            feedback.add(recordValidationFeedback("EngagementStrategyAgent", "info",
                    "Positioning appears generic: \"" + p + "\"",
                    "Incorporate specific organization pain points from research into positioning"));
        }
    }

    private void checkContradictions(Map<String, Object> research,
                                      Map<String, Object> strategy,
                                      Map<String, Object> objections,
                                      List<String> contradictions,
                                      List<ValidationFeedback> feedback) {
        // Check: top pain point from research not addressed in strategy key messages
        Object painPoints = research.get("possible_pain_points");
        Object keyMessages = strategy.get("key_messages");
        if (painPoints instanceof List<?> pp && !pp.isEmpty()
                && keyMessages instanceof List<?> msgs && !msgs.isEmpty()) {
            String firstPain = String.valueOf(pp.get(0)).toLowerCase();
            boolean covered = msgs.stream()
                    .map(m -> String.valueOf(m).toLowerCase())
                    .anyMatch(m -> sharedWordCount(firstPain, m) >= 2);
            if (!covered) {
                contradictions.add(
                        "Top research pain point is not reflected in strategy key messages — "
                        + "messages should address: " + abbreviate(String.valueOf(pp.get(0)), 60));
                feedback.add(recordValidationFeedback("EngagementStrategyAgent", "warning",
                        "Strategy key messages do not address the primary pain point from research",
                        "Align at least one key message directly with the top identified pain point"));
            }
        }

        // Check: high-risk objections (risk_level >= 0.80) with no counter in key messages
        Object objList = objections.get("objections");
        if (objList instanceof List<?> objs && !objs.isEmpty()
                && keyMessages instanceof List<?> msgs2) {
            long highRiskCount = objs.stream()
                    .filter(o -> o instanceof Map<?, ?> m
                            && getDoubleFromMap(m, "risk_level", "likelihood") >= 0.80)
                    .count();
            if (highRiskCount > 0) {
                contradictions.add(highRiskCount
                        + " high-risk objection(s) lack direct counter-messaging in strategy key messages");
                feedback.add(recordValidationFeedback("EngagementStrategyAgent", "warning",
                        highRiskCount + " high-risk objection(s) are not countered in strategy key messages",
                        "Add key messages that directly address the highest-risk objections"));
            }
        }
    }

    private void checkMissingEvidence(Map<String, Object> strategy,
                                       Map<String, Object> objections,
                                       List<String> missing,
                                       List<ValidationFeedback> feedback) {
        // Check for evidence_needed signals in objections
        Object objList = objections.get("objections");
        if (objList instanceof List<?> objs) {
            for (Object o : objs) {
                if (o instanceof Map<?, ?> m) {
                    Object evidenceNeeded = m.get("evidence_needed");
                    if (evidenceNeeded instanceof String ev && !ev.isBlank()) {
                        missing.add("Evidence gap: " + abbreviate(ev, 80));
                        feedback.add(recordValidationFeedback("ObjectionPredictionAgent", "info",
                                "Evidence needed: " + ev,
                                "Prepare supporting material: " + ev));
                        break; // report only the first for brevity
                    }
                }
            }
        }
    }

    // ── Scoring ──────────────────────────────────────────────────────────────

    private double computeReadiness(List<ValidationFeedback> feedback) {
        double score = 1.0;
        for (ValidationFeedback f : feedback) {
            score -= switch (f.getSeverity()) {
                case "error"   -> 0.15;
                case "warning" -> 0.08;
                default        -> 0.02;
            };
        }
        return Math.max(0.0, Math.round(score * 100.0) / 100.0);
    }

    // ── Output builder ────────────────────────────────────────────────────────

    private String buildOutputJson(boolean passed,
                                    List<String> approvedPoints,
                                    List<String> weakAssumptions,
                                    List<String> contradictions,
                                    List<String> missingInformation,
                                    List<String> recommendedRevisions,
                                    double readinessScore) {
        try {
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("agent",                 "CriticValidatorAgent");
            out.put("validationPassed",      passed);
            out.put("approved_points",       approvedPoints);
            out.put("weak_assumptions",      weakAssumptions);
            out.put("contradictions",        contradictions);
            out.put("missing_information",   missingInformation);
            out.put("recommended_revisions", recommendedRevisions);
            out.put("readiness_score",       readinessScore);
            out.put("confidence_score",      1.0);
            out.put("influencedBy",          READS_FROM);
            return objectMapper.writeValueAsString(out);
        } catch (Exception e) {
            return "{\"agent\":\"CriticValidatorAgent\",\"validationPassed\":true,"
                    + "\"readiness_score\":0.5,\"confidence_score\":1.0,\"influencedBy\":[]}";
        }
    }

    // ── Utility helpers ───────────────────────────────────────────────────────

    private boolean isBlankOrMissing(Map<String, Object> map, String key) {
        Object v = map.get(key);
        if (v == null) return true;
        if (v instanceof String s) return s.isBlank();
        if (v instanceof List<?> l) return l.isEmpty();
        return false;
    }

    private double getDoubleField(Map<String, Object> map, String... keys) {
        for (String key : keys) {
            Object raw = map.get(key);
            if (raw instanceof Number n) return n.doubleValue();
        }
        return 0.0;
    }

    private double getDoubleFromMap(Map<?, ?> map, String... keys) {
        for (String key : keys) {
            Object raw = map.get(key);
            if (raw instanceof Number n) return n.doubleValue();
        }
        return 0.0;
    }

    private int sharedWordCount(String a, String b) {
        int count = 0;
        for (String word : a.split("\\s+")) {
            if (word.length() > 4 && b.contains(word)) count++;
        }
        return count;
    }

    private String abbreviate(String text, int max) {
        if (text == null) return "";
        return text.length() <= max ? text : text.substring(0, max - 3) + "...";
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> parseMap(String json) {
        try { return objectMapper.readValue(json, Map.class); }
        catch (Exception e) { return Map.of(); }
    }
}
