package com.argusoft.meetwise.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record UserMeetingDTO(
        UUID meetingRequestId,
        String organizationName,
        String meetingObjective,
        String stakeholderRole,
        String status,
        LocalDateTime createdAt,
        Double overallConfidence
) {}
