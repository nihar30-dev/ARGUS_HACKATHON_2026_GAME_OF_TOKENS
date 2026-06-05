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

    @Column(name = "session_id", nullable = false, unique = true)
    private UUID sessionId;

    @Column(name = "meeting_request_id", nullable = false)
    private UUID meetingRequestId;

    @Column(name = "executive_brief", columnDefinition = "TEXT")
    private String executiveBrief;

    @Column(name = "conversation_flow_json", columnDefinition = "TEXT")
    private String conversationFlowJson;

    @Column(name = "questions_json", columnDefinition = "TEXT")
    private String questionsJson;

    @Column(name = "objection_responses_json", columnDefinition = "TEXT")
    private String objectionResponsesJson;

    @Column(name = "next_steps_json", columnDefinition = "TEXT")
    private String nextStepsJson;

    @Column(name = "overall_confidence", nullable = false)
    private double overallConfidence;

    @Column(name = "generated_at", nullable = false)
    @Builder.Default
    private LocalDateTime generatedAt = LocalDateTime.now();
}
