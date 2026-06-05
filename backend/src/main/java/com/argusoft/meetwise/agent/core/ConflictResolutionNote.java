package com.argusoft.meetwise.agent.core;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class ConflictResolutionNote {

    private List<String> conflictingAgents;
    private String conflictDescription;
    private String resolution;
    private String resolvedBy;
}
