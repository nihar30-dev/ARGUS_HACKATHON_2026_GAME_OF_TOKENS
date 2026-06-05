package com.argusoft.meetwise.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "final_reports")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinalReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "meeting_request_id", nullable = false, unique = true)
    private UUID meetingRequestId;

    // Full FinalSynthesisAgent JSON stored as JSONB for queryability
    @Column(name = "report_payload", nullable = false, columnDefinition = "jsonb")
    private String reportPayload;

    @Column(name = "overall_confidence", nullable = false)
    private double overallConfidence;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
