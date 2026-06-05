package com.argusoft.meetwise.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MeetingRequestDTO(
        @NotBlank(message = "Organization name is required")
        @Size(max = 255)
        String organizationName,

        @NotBlank(message = "Meeting objective is required")
        String meetingObjective,

        @NotBlank(message = "Offering description is required")
        String offeringDescription,

        @NotBlank(message = "Stakeholder role is required")
        @Size(max = 255)
        String stakeholderRole
) {}
