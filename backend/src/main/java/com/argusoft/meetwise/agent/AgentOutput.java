package com.argusoft.meetwise.agent;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AgentOutput {
    private String agentName;
    private String outputJson;
    private double confidenceScore;
    private List<String> influencedBy;
    private boolean usedGemini;
    private String inputSummary;
    private String outputSummary;
}
