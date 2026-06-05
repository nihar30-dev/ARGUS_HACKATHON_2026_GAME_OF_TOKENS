package com.argusoft.meetwise.dto;

import com.argusoft.meetwise.entity.AgentTrace;

import java.time.LocalDateTime;
import java.util.UUID;

public record AgentTraceDTO(
        UUID id,
        UUID meetingRequestId,
        String sourceAgent,
        String targetAgent,
        String inputSummary,
        String outputSummary,
        String influenceDescription,
        LocalDateTime createdAt
) {
    public static AgentTraceDTO from(AgentTrace trace) {
        return new AgentTraceDTO(
                trace.getId(), trace.getMeetingRequestId(),
                trace.getSourceAgent(), trace.getTargetAgent(),
                trace.getInputSummary(), trace.getOutputSummary(),
                trace.getInfluenceDescription(), trace.getCreatedAt()
        );
    }
}
