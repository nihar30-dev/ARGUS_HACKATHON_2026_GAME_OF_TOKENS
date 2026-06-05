package com.argusoft.meetwise.agent.core;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ValidationFeedback {

    private String fromAgent;

    /** error | warning | info */
    private String severity;

    private String issue;
    private String suggestion;

    @Builder.Default
    private boolean applied = false;
}
