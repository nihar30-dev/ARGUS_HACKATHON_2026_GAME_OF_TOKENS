package com.argusoft.meetwise.dto;

import java.util.List;
import java.util.UUID;

public record MeetingSessionResponseDTO(
        UUID sessionId,
        UUID meetingRequestId,
        String organizationName,
        String status,
        List<AgentRunDTO> agentRuns,
        List<AgentTraceDTO> traces,
        FinalReportDTO finalReport
) {}
