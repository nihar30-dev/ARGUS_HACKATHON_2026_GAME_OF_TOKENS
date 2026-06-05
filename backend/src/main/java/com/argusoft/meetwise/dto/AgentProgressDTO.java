package com.argusoft.meetwise.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * WebSocket message published to /topic/meetings/{id}/progress after each agent step.
 *
 * type values:
 *   AGENT_START      — agent about to run (agentName, executionOrder, pipelineStatus)
 *   AGENT_COMPLETE   — agent finished (+ status, confidenceScore, usedGemini, executionMs)
 *   PIPELINE_COMPLETE — all agents done (+ organizationName, agentRuns, traces, finalReport)
 *   PIPELINE_FAILED  — pipeline error (+ errorMessage)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AgentProgressDTO {
    private String type;
    private String meetingRequestId;

    // Included in PIPELINE_COMPLETE so Flutter can build SessionResponse directly
    private String organizationName;
    private String meetingObjective;
    private String stakeholderRole;

    // Per-agent fields (AGENT_START / AGENT_COMPLETE)
    private String  agentName;
    private Integer executionOrder;
    private String  status;
    private Double  confidenceScore;
    private Boolean usedGemini;
    private Long    executionMs;

    // Pipeline-level
    private String pipelineStatus;
    private String errorMessage;

    // Full session data (PIPELINE_COMPLETE only)
    private List<AgentRunDTO>   agentRuns;
    private List<AgentTraceDTO> traces;
    private FinalReportDTO      finalReport;
}
