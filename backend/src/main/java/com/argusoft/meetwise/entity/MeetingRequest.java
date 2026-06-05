package com.argusoft.meetwise.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

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

    @Column(name = "session_id")
    private UUID sessionId;

    @Column(name = "organization_name", nullable = false)
    private String organizationName;

    @Column(name = "meeting_objective", nullable = false, columnDefinition = "TEXT")
    private String meetingObjective;

    @Column(name = "offering_description", nullable = false, columnDefinition = "TEXT")
    private String offeringDescription;

    @Column(name = "stakeholder_role", nullable = false)
    private String stakeholderRole;

    @Column(nullable = false)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
