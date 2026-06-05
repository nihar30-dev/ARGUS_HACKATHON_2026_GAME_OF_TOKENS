package com.argusoft.meetwise.service;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentResult;
import com.argusoft.meetwise.agent.core.AgentTraceMessage;
import com.argusoft.meetwise.dto.*;
import com.argusoft.meetwise.entity.*;
import com.argusoft.meetwise.exception.MeetwiseException;
import com.argusoft.meetwise.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MeetingOrchestrationService {

    private final List<Agent>                 agents;
    private final MeetingRequestRepository    meetingRequestRepository;
    private final AgentRunRepository          agentRunRepository;
    private final AgentTraceRepository        agentTraceRepository;
    private final FinalReportRepository       finalReportRepository;
    private final ObjectMapper                objectMapper;
    private final SimpMessagingTemplate       messagingTemplate;

    // Self-reference so @Async works via Spring proxy (field injection, not constructor)
    @Autowired @Lazy
    private MeetingOrchestrationService self;

    // -----------------------------------------------------------------------
    // Public API — returns immediately; pipeline runs in background
    // -----------------------------------------------------------------------

    public MeetingStartResponseDTO orchestrate(MeetingRequestDTO dto) {
        MeetingRequest meeting = meetingRequestRepository.save(MeetingRequest.builder()
                .organizationName(dto.organizationName())
                .stakeholderRole(dto.stakeholderRole())
                .meetingObjective(dto.meetingObjective())
                .offeringDescription(dto.offeringDescription())
                .status("RUNNING")
                .build());

        self.runPipelineAsync(meeting.getId());
        log.info("[Orchestrate] Meeting {} queued for async pipeline", meeting.getId());
        return new MeetingStartResponseDTO(meeting.getId(), meeting.getOrganizationName(), "RUNNING");
    }

    @Transactional
    public MeetingStartResponseDTO runById(UUID meetingId) {
        MeetingRequest meeting = meetingRequestRepository.findById(meetingId)
                .orElseThrow(() -> new MeetwiseException("Meeting not found: " + meetingId));

        agentRunRepository.deleteByMeetingRequestId(meetingId);
        agentTraceRepository.deleteByMeetingRequestId(meetingId);
        finalReportRepository.deleteByMeetingRequestId(meetingId);

        meeting.setStatus("RUNNING");
        meetingRequestRepository.save(meeting);

        self.runPipelineAsync(meetingId);
        log.info("[RunById] Meeting {} re-queued for async pipeline", meetingId);
        return new MeetingStartResponseDTO(meetingId, meeting.getOrganizationName(), "RUNNING");
    }

    public MeetingSessionResponseDTO getSession(UUID meetingId) {
        MeetingRequest   meeting = meetingRequestRepository.findById(meetingId)
                .orElseThrow(() -> new MeetwiseException("Meeting not found: " + meetingId));
        List<AgentRun>   runs    = agentRunRepository
                .findByMeetingRequestIdOrderByExecutionOrderAsc(meetingId);
        List<AgentTrace> traces  = agentTraceRepository
                .findByMeetingRequestIdOrderByCreatedAtAsc(meetingId);
        FinalReport      report  = finalReportRepository.findByMeetingRequestId(meetingId).orElse(null);
        return buildResponse(meeting, runs, traces, report);
    }

    // -----------------------------------------------------------------------
    // Async pipeline — runs in background thread, publishes WS events
    // -----------------------------------------------------------------------

    @Async("pipelineExecutor")
    public void runPipelineAsync(UUID meetingId) {
        String topic = "/topic/meetings/" + meetingId + "/progress";

        MeetingRequest meeting = meetingRequestRepository.findById(meetingId)
                .orElseThrow(() -> new MeetwiseException("Meeting not found: " + meetingId));

        AgentContext   context  = new AgentContext(meeting);
        List<AgentRun> runs     = new ArrayList<>();

        List<Agent> pipeline = agents.stream()
                .sorted(Comparator.comparingInt(Agent::getOrder))
                .collect(Collectors.toList());

        try {
            for (Agent agent : pipeline) {
                // Notify client this agent is starting
                messagingTemplate.convertAndSend(topic, AgentProgressDTO.builder()
                        .type("AGENT_START")
                        .meetingRequestId(meetingId.toString())
                        .agentName(agent.getName())
                        .executionOrder(agent.getOrder())
                        .pipelineStatus("RUNNING")
                        .build());

                log.info("[Pipeline {}] Running {} (order {})", meetingId, agent.getName(), agent.getOrder());
                long start  = System.currentTimeMillis();
                AgentResult result  = agent.execute(context);
                long execMs = System.currentTimeMillis() - start;

                context.putOutput(agent.getName(), result.getOutputJson());
                runs.add(agentRunRepository.save(toAgentRun(meetingId, result, execMs)));

                // Notify client this agent completed
                messagingTemplate.convertAndSend(topic, AgentProgressDTO.builder()
                        .type("AGENT_COMPLETE")
                        .meetingRequestId(meetingId.toString())
                        .agentName(result.getAgentName())
                        .executionOrder(getOrder(result.getAgentName()))
                        .status(result.getStatus() != null ? result.getStatus().name() : "SUCCESS")
                        .confidenceScore(result.getConfidenceScore())
                        .usedGemini(result.isUsedGemini())
                        .executionMs(execMs)
                        .pipelineStatus("RUNNING")
                        .build());

                log.info("[Pipeline {}] {} done in {}ms  confidence={}", meetingId,
                        agent.getName(), execMs, result.getConfidenceScore());
            }

            List<AgentTrace> traces = persistAllTraces(meetingId, context);
            meeting.setStatus("COMPLETED");
            meetingRequestRepository.save(meeting);
            FinalReport report = saveFinalReport(meetingId, context.getOutput("FinalSynthesisAgent"));

            log.info("[Pipeline {}] COMPLETED — {} runs, {} traces", meetingId, runs.size(), traces.size());

            MeetingSessionResponseDTO full = buildResponse(meeting, runs, traces, report);

            // Send full session so Flutter can build SessionResponse without a second REST call
            messagingTemplate.convertAndSend(topic, AgentProgressDTO.builder()
                    .type("PIPELINE_COMPLETE")
                    .meetingRequestId(meetingId.toString())
                    .organizationName(meeting.getOrganizationName())
                    .meetingObjective(meeting.getMeetingObjective())
                    .stakeholderRole(meeting.getStakeholderRole())
                    .pipelineStatus("COMPLETED")
                    .agentRuns(full.agentRuns())
                    .traces(full.traces())
                    .finalReport(full.finalReport())
                    .build());

        } catch (Exception e) {
            log.error("[Pipeline {}] Failed: {}", meetingId, e.getMessage(), e);
            try {
                meeting.setStatus("FAILED");
                meetingRequestRepository.save(meeting);
            } catch (Exception ignored) {}

            messagingTemplate.convertAndSend(topic, AgentProgressDTO.builder()
                    .type("PIPELINE_FAILED")
                    .meetingRequestId(meetingId.toString())
                    .pipelineStatus("FAILED")
                    .errorMessage(e.getMessage())
                    .build());
        }
    }

    // -----------------------------------------------------------------------
    // Trace persistence
    // -----------------------------------------------------------------------

    private List<AgentTrace> persistAllTraces(UUID meetingId, AgentContext context) {
        List<AgentTrace> saved = new ArrayList<>();
        for (AgentTraceMessage msg : context.getTraceMessages()) {
            String description = msg.getSourceAgent() + " → " + msg.getTargetAgent()
                    + " [" + msg.getMessageType() + "]: " + msg.getContent();
            saved.add(agentTraceRepository.save(AgentTrace.builder()
                    .meetingRequestId(meetingId)
                    .sourceAgent(msg.getSourceAgent())
                    .targetAgent(msg.getTargetAgent())
                    .influenceType(msg.getMessageType())
                    .inputSummary(msg.getContent())
                    .outputSummary("Edge type: " + msg.getMessageType())
                    .influenceDescription(description)
                    .build()));
        }
        return saved;
    }

    // -----------------------------------------------------------------------
    // AgentRun persistence
    // -----------------------------------------------------------------------

    private AgentRun toAgentRun(UUID meetingId, AgentResult result, long executionMs) {
        return AgentRun.builder()
                .meetingRequestId(meetingId)
                .agentName(result.getAgentName())
                .agentType(result.getAgentType()  != null ? result.getAgentType().name()  : null)
                .agentStatus(result.getStatus()   != null ? result.getStatus().name()     : "SUCCESS")
                .executionOrder(getOrder(result.getAgentName()))
                .inputPayload(buildInputPayload(result.getInputSummary()))
                .outputPayload(result.getOutputJson())
                .confidenceScore(result.getConfidenceScore())
                .influencedBy(result.getInfluencedBy() == null ? ""
                        : String.join(",", result.getInfluencedBy()))
                .traceSummary(result.getTraceSummary())
                .influenceSummary(result.getInfluenceSummary())
                .usedGemini(result.isUsedGemini())
                .executionMs(executionMs)
                .build();
    }

    // -----------------------------------------------------------------------
    // Final report
    // -----------------------------------------------------------------------

    private FinalReport saveFinalReport(UUID meetingId, String finalJson) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = objectMapper.readValue(finalJson, Map.class);
            double confidence = toDouble(data.getOrDefault("readiness_score",
                    data.getOrDefault("overallConfidenceScore", data.get("confidence_score"))));
            return finalReportRepository.save(FinalReport.builder()
                    .meetingRequestId(meetingId)
                    .reportPayload(finalJson)
                    .overallConfidence(confidence)
                    .build());
        } catch (Exception e) {
            log.error("[Meeting {}] Failed to parse final synthesis JSON: {}", meetingId, e.getMessage());
            String fallback = "{\"executive_brief\":\"Meeting preparation complete.\","
                    + "\"readiness_score\":0.5,\"confidence_score\":0.5,\"overallConfidenceScore\":0.5}";
            return finalReportRepository.save(FinalReport.builder()
                    .meetingRequestId(meetingId)
                    .reportPayload(fallback)
                    .overallConfidence(0.5)
                    .build());
        }
    }

    // -----------------------------------------------------------------------
    // Response builder
    // -----------------------------------------------------------------------

    private MeetingSessionResponseDTO buildResponse(MeetingRequest meeting,
                                                     List<AgentRun> runs,
                                                     List<AgentTrace> traces,
                                                     FinalReport report) {
        return new MeetingSessionResponseDTO(
                meeting.getId(),
                meeting.getOrganizationName(),
                meeting.getMeetingObjective(),
                meeting.getStakeholderRole(),
                meeting.getStatus(),
                runs.stream().map(AgentRunDTO::from).collect(Collectors.toList()),
                traces.stream().map(AgentTraceDTO::from).collect(Collectors.toList()),
                report != null ? FinalReportDTO.from(report, objectMapper) : null);
    }

    // -----------------------------------------------------------------------
    // Utilities
    // -----------------------------------------------------------------------

    private String buildInputPayload(String inputSummary) {
        try {
            return objectMapper.writeValueAsString(
                    Map.of("summary", inputSummary != null ? inputSummary : ""));
        } catch (Exception e) {
            return "{\"summary\":\"\"}";
        }
    }

    private int getOrder(String agentName) {
        return switch (agentName) {
            case "OrganizationResearchAgent"  -> 1;
            case "StakeholderPersonaAgent"    -> 2;
            case "EngagementStrategyAgent"    -> 3;
            case "ObjectionPredictionAgent"   -> 4;
            case "CriticValidatorAgent"       -> 5;
            case "StrategyRefinementAgent"    -> 6;
            case "FinalSynthesisAgent"        -> 7;
            default -> 99;
        };
    }

    private double toDouble(Object o) {
        if (o == null) return 0.5;
        if (o instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(o.toString()); } catch (Exception e) { return 0.5; }
    }
}
