package com.argusoft.meetwise.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "input_payload", columnDefinition = "jsonb")
    private String inputPayload;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "output_payload", nullable = false, columnDefinition = "jsonb")
    private String outputPayload;

    @Column(name = "confidence_score", nullable = false)
    private double confidenceScore;

    @Column(name = "influenced_by")
    private String influencedBy;

    @Column(name = "agent_type")
    private String agentType;

    @Column(name = "agent_status")
    private String agentStatus;

    @Column(name = "trace_summary", columnDefinition = "TEXT")
    private String traceSummary;

    @Column(name = "influence_summary", columnDefinition = "TEXT")
    private String influenceSummary;

    @Column(name = "used_gemini", nullable = false)
    private boolean usedGemini;

    @Column(name = "execution_ms", nullable = false)
    private long executionMs;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
