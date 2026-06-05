package com.argusoft.meetwise.dto;

import com.argusoft.meetwise.entity.MeetingRequest;

import java.time.LocalDateTime;
import java.util.UUID;

public record CreateMeetingResponseDTO(
        UUID id,
        String organizationName,
        String stakeholderRole,
        String meetingObjective,
        String offeringDescription,
        String status,
        LocalDateTime createdAt
) {
    public static CreateMeetingResponseDTO from(MeetingRequest req) {
        return new CreateMeetingResponseDTO(
                req.getId(),
                req.getOrganizationName(),
                req.getStakeholderRole(),
                req.getMeetingObjective(),
                req.getOfferingDescription(),
                req.getStatus(),
                req.getCreatedAt()
        );
    }
}
