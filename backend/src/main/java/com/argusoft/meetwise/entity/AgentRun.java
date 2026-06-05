package com.argusoft.meetwise.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "agent_runs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgentRun {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "meeting_request_id", nullable = false)
    private UUID meetingRequestId;

    @Column(name = "agent_name", nullable = false)
    private String agentName;

    @Column(name = "execution_order", nullable = false)
    private int executionOrder;

    // JSONB — stored as serialised JSON string; PostgreSQL type handles querying
    @Column(name = "input_payload", columnDefinition = "jsonb")
    private String inputPayload;

    @Column(name = "output_payload", nullable = false, columnDefinition = "jsonb")
    private String outputPayload;

    @Column(name = "confidence_score", nullable = false)
    private double confidenceScore;

    @Column(name = "influenced_by")
    private String influencedBy;

    @Column(name = "used_gemini", nullable = false)
    private boolean usedGemini;

    @Column(name = "execution_ms", nullable = false)
    private long executionMs;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
