package com.argusoft.meetwise.dto;

import java.util.List;
import java.util.UUID;

public record MeetingSessionResponseDTO(
        UUID meetingRequestId,
        String organizationName,
        String meetingObjective,
        String stakeholderRole,
        String status,
        List<AgentRunDTO> agentRuns,
        List<AgentTraceDTO> traces,
        FinalReportDTO finalReport
) {}
