package com.argusoft.meetwise.agent.core;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AgentTraceMessage {

    private String sourceAgent;
    private String targetAgent;

    /** INFLUENCE | VALIDATION | REFINEMENT | CONFLICT_RESOLUTION */
    private String messageType;

    private String content;

    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();
}
