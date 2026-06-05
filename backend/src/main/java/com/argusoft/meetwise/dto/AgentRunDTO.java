package com.argusoft.meetwise.dto;

import com.argusoft.meetwise.entity.AgentRun;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public record AgentRunDTO(
        UUID id,
        UUID sessionId,
        String agentName,
        int executionOrderIndex,
        String inputJson,
        String outputJson,
        double confidenceScore,
        List<String> influencedBy,
        boolean usedGemini,
        long executionMs,
        LocalDateTime executedAt
) {
    public static AgentRunDTO from(AgentRun run) {
        List<String> influenced = (run.getInfluencedBy() == null || run.getInfluencedBy().isBlank())
                ? List.of()
                : Arrays.asList(run.getInfluencedBy().split(","));
        return new AgentRunDTO(
                run.getId(), run.getSessionId(), run.getAgentName(),
                run.getExecutionOrderIndex(), run.getInputJson(), run.getOutputJson(),
                run.getConfidenceScore(), influenced, run.isUsedGemini(),
                run.getExecutionMs(), run.getExecutedAt()
        );
    }
}
