package com.argusoft.meetwise.agent;

import com.argusoft.meetwise.agent.core.AgentStatus;
import com.argusoft.meetwise.agent.core.AgentType;
import com.argusoft.meetwise.agent.core.ConflictResolutionNote;
import com.argusoft.meetwise.agent.core.ValidationFeedback;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@Builder(toBuilder = true)
public class AgentResult {

    // --- Identity ---
    private String agentName;
    private AgentType agentType;
    private AgentStatus status;

    // --- Input/output payloads ---
    private Map<String, Object> inputSnapshot;
    private Map<String, Object> output;
    private String outputJson;

    // --- Confidence and reasoning ---
    private double confidenceScore;
    private List<String> assumptions;

    // --- Influence chain ---
    private List<String> influencedBy;
    private List<String> influences;
    private String influenceSummary;

    // --- Trace ---
    private String traceSummary;

    // --- Validation and conflict ---
    private List<ValidationFeedback> validationFeedback;
    private List<ConflictResolutionNote> conflictResolutionNotes;

    // --- Error ---
    private String errorMessage;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    // --- Backward-compat fields (mirrors legacy AgentOutput) ---
    private boolean usedGemini;
    private String inputSummary;
    private String outputSummary;

    // --- RAG traceability ---
    private boolean ragContextUsed;

    @Builder.Default
    private List<String> ragChunkIds = new java.util.ArrayList<>();

    private String ragSummary;

    @Builder.Default
    private List<String> evidenceGaps = new java.util.ArrayList<>();
}
