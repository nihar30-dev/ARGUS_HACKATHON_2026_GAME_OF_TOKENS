package com.argusoft.meetwise.dto;

import com.argusoft.meetwise.entity.AgentRun;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public record AgentRunDTO(
        UUID id,
        UUID meetingRequestId,
        String agentName,
        String agentType,
        String status,
        int executionOrder,
        String inputPayload,
        String outputPayload,
        double confidenceScore,
        List<String> influencedBy,
        String traceSummary,
        boolean usedGemini,
        long executionMs,
        LocalDateTime createdAt
) {
    public static AgentRunDTO from(AgentRun run) {
        List<String> influenced = (run.getInfluencedBy() == null || run.getInfluencedBy().isBlank())
                ? List.of()
                : Arrays.asList(run.getInfluencedBy().split(","));
        return new AgentRunDTO(
                run.getId(), run.getMeetingRequestId(), run.getAgentName(),
                run.getAgentType(), run.getAgentStatus() != null ? run.getAgentStatus() : "SUCCESS",
                run.getExecutionOrder(), run.getInputPayload(), run.getOutputPayload(),
                run.getConfidenceScore(), influenced,
                run.getTraceSummary(), run.isUsedGemini(),
                run.getExecutionMs(), run.getCreatedAt()
        );
    }
}
