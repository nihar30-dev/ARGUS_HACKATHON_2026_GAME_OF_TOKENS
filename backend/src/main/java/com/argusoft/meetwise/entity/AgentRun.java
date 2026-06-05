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

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "agent_name", nullable = false)
    private String agentName;

    @Column(name = "execution_order_index", nullable = false)
    private int executionOrderIndex;

    @Column(name = "input_json", columnDefinition = "TEXT")
    private String inputJson;

    @Column(name = "output_json", nullable = false, columnDefinition = "TEXT")
    private String outputJson;

    @Column(name = "confidence_score", nullable = false)
    private double confidenceScore;

    @Column(name = "influenced_by")
    private String influencedBy;

    @Column(name = "used_gemini", nullable = false)
    private boolean usedGemini;

    @Column(name = "execution_ms", nullable = false)
    private long executionMs;

    @Column(name = "executed_at", nullable = false)
    @Builder.Default
    private LocalDateTime executedAt = LocalDateTime.now();
}
