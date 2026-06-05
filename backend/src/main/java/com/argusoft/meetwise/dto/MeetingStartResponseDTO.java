package com.argusoft.meetwise.dto;

import java.util.UUID;

public record MeetingStartResponseDTO(
        UUID meetingRequestId,
        String organizationName,
        String status
) {}
