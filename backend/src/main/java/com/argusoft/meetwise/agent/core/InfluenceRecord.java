package com.argusoft.meetwise.agent.core;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class InfluenceRecord {

    private String sourceAgent;
    private String targetAgent;

    /** DATA, FEEDBACK, VALIDATION, REFINEMENT */
    private String influenceType;

    private String description;

    @Builder.Default
    private double confidenceWeight = 1.0;
}
