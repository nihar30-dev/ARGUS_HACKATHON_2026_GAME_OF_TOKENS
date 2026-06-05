package com.argusoft.meetwise.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "meeting_requests")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MeetingRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "organization_name", nullable = false)
    private String organizationName;

    @Column(name = "stakeholder_role", nullable = false)
    private String stakeholderRole;

    @Column(name = "meeting_objective", nullable = false, columnDefinition = "TEXT")
    private String meetingObjective;

    @Column(name = "offering_description", nullable = false, columnDefinition = "TEXT")
    private String offeringDescription;

    @Column(nullable = false)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
