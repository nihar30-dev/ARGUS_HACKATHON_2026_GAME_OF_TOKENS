package com.argusoft.meetwise.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "agent_trace")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgentTrace {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "source_agent", nullable = false)
    private String sourceAgent;

    @Column(name = "target_agent", nullable = false)
    private String targetAgent;

    @Column(name = "input_summary", columnDefinition = "TEXT")
    private String inputSummary;

    @Column(name = "output_summary", columnDefinition = "TEXT")
    private String outputSummary;

    @Column(name = "influence_description", columnDefinition = "TEXT")
    private String influenceDescription;

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();
}
