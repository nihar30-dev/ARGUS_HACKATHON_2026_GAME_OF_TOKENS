package com.argusoft.meetwise.service;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentOutput;
import com.argusoft.meetwise.dto.*;
import com.argusoft.meetwise.entity.*;
import com.argusoft.meetwise.exception.MeetwiseException;
import com.argusoft.meetwise.exception.ResourceNotFoundException;
import com.argusoft.meetwise.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MeetingOrchestrationService {

    private static final UUID DEMO_SESSION_ID =
            UUID.fromString("00000000-0000-0000-0000-000000000001");

    private final List<Agent> agents;
    private final MeetingRequestRepository meetingRequestRepository;
    private final AgentRunRepository agentRunRepository;
    private final AgentTraceRepository agentTraceRepository;
    private final FinalReportRepository finalReportRepository;
    private final ObjectMapper objectMapper;

    // -------------------------------------------------------------------------
    // POST /api/meetings — create a meeting record, return immediately (PENDING)
    // -------------------------------------------------------------------------
    @Transactional
    public CreateMeetingResponseDTO create(MeetingRequestDTO dto) {
        MeetingRequest meeting = meetingRequestRepository.save(MeetingRequest.builder()
                .organizationName(dto.organizationName())
                .stakeholderRole(dto.stakeholderRole())
                .meetingObjective(dto.meetingObjective())
                .offeringDescription(dto.offeringDescription())
                .status("PENDING")
                .build());
        log.info("Created meeting {} for '{}'", meeting.getId(), meeting.getOrganizationName());
        return CreateMeetingResponseDTO.from(meeting);
    }

    // -------------------------------------------------------------------------
    // POST /api/meetings/{id}/run — run the 6-agent pipeline synchronously
    // -------------------------------------------------------------------------
    @Transactional
    public MeetingSessionResponseDTO runPipeline(UUID meetingId) {
        MeetingRequest meeting = meetingRequestRepository.findById(meetingId)
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found: " + meetingId));

        if (!"PENDING".equals(meeting.getStatus())) {
            throw new MeetwiseException(
                    "Meeting " + meetingId + " cannot be run — status is '" + meeting.getStatus()
                    + "' (expected PENDING)", 400);
        }

        log.info("[Meeting {}] Starting agent pipeline for '{}'", meetingId, meeting.getOrganizationName());
        return executePipeline(meeting);
    }

    // -------------------------------------------------------------------------
    // GET /api/meetings/{id} — full session (runs + traces + report)
    // -------------------------------------------------------------------------
    public MeetingSessionResponseDTO getSession(UUID meetingId) {
        MeetingRequest meeting = meetingRequestRepository.findById(meetingId)
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found: " + meetingId));
        List<AgentRun> runs = agentRunRepository
                .findByMeetingRequestIdOrderByExecutionOrderAsc(meetingId);
        List<AgentTrace> traces = agentTraceRepository
                .findByMeetingRequestIdOrderByCreatedAtAsc(meetingId);
        FinalReport report = finalReportRepository.findByMeetingRequestId(meetingId).orElse(null);
        return buildResponse(meeting, runs, traces, report);
    }

    // -------------------------------------------------------------------------
    // GET /api/meetings/{id}/trace — just the trace rows
    // -------------------------------------------------------------------------
    public List<AgentTraceDTO> getTraces(UUID meetingId) {
        if (!meetingRequestRepository.existsById(meetingId)) {
            throw new ResourceNotFoundException("Meeting not found: " + meetingId);
        }
        return agentTraceRepository
                .findByMeetingRequestIdOrderByCreatedAtAsc(meetingId)
                .stream()
                .map(AgentTraceDTO::from)
                .collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // GET /api/meetings/{id}/report — just the final report
    // -------------------------------------------------------------------------
    public FinalReportDTO getReport(UUID meetingId) {
        if (!meetingRequestRepository.existsById(meetingId)) {
            throw new ResourceNotFoundException("Meeting not found: " + meetingId);
        }
        return finalReportRepository.findByMeetingRequestId(meetingId)
                .map(r -> FinalReportDTO.from(r, objectMapper))
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Report not ready for meeting: " + meetingId));
    }

    // -------------------------------------------------------------------------
    // GET /api/meetings/demo — always-available demo session (Apollo Hospitals)
    // -------------------------------------------------------------------------
    public MeetingSessionResponseDTO getDemoSession() {
        return getSession(DEMO_SESSION_ID);
    }

    // -------------------------------------------------------------------------
    // Internal pipeline execution
    // -------------------------------------------------------------------------
    private MeetingSessionResponseDTO executePipeline(MeetingRequest meeting) {
        UUID meetingId = meeting.getId();
        AgentContext context = new AgentContext(meeting);
        List<AgentRun> runs = new ArrayList<>();
        List<AgentTrace> traces = new ArrayList<>();

        List<Agent> pipeline = agents.stream()
                .sorted(Comparator.comparingInt(Agent::getOrder))
                .toList();

        for (Agent agent : pipeline) {
            log.info("[Meeting {}] Running {} (order {})", meetingId, agent.getName(), agent.getOrder());
            long start = System.currentTimeMillis();

            AgentOutput output = agent.execute(context);
            long executionMs = System.currentTimeMillis() - start;

            context.putOutput(agent.getName(), output.getOutputJson());

            AgentRun run = agentRunRepository.save(toAgentRun(meetingId, output, executionMs));
            runs.add(run);

            List<AgentTrace> agentTraces = buildTraces(meetingId, output);
            traces.addAll(agentTraceRepository.saveAll(agentTraces));

            log.info("[Meeting {}] {} done in {}ms, confidence={}",
                    meetingId, agent.getName(), executionMs, output.getConfidenceScore());
        }

        meeting.setStatus("COMPLETED");
        meetingRequestRepository.save(meeting);

        FinalReport report = saveFinalReport(meetingId, context.getOutput("FinalSynthesisAgent"));
        log.info("[Meeting {}] Pipeline complete, overall confidence={}",
                meetingId, report.getOverallConfidence());

        return buildResponse(meeting, runs, traces, report);
    }

    private AgentRun toAgentRun(UUID meetingId, AgentOutput output, long executionMs) {
        return AgentRun.builder()
                .meetingRequestId(meetingId)
                .agentName(output.getAgentName())
                .executionOrder(getOrder(output.getAgentName()))
                .inputPayload(wrapSummary(output.getInputSummary()))
                .outputPayload(output.getOutputJson())
                .confidenceScore(output.getConfidenceScore())
                .influencedBy(output.getInfluencedBy() == null ? ""
                        : String.join(",", output.getInfluencedBy()))
                .usedGemini(output.isUsedGemini())
                .executionMs(executionMs)
                .build();
    }

    private List<AgentTrace> buildTraces(UUID meetingId, AgentOutput output) {
        if (output.getInfluencedBy() == null || output.getInfluencedBy().isEmpty()) return List.of();
        return output.getInfluencedBy().stream()
                .map(source -> AgentTrace.builder()
                        .meetingRequestId(meetingId)
                        .sourceAgent(source)
                        .targetAgent(output.getAgentName())
                        .inputSummary(output.getInputSummary())
                        .outputSummary(output.getOutputSummary())
                        .influenceDescription(source + " output provided context that shaped "
                                + output.getAgentName() + "'s analysis")
                        .build())
                .collect(Collectors.toList());
    }

    private FinalReport saveFinalReport(UUID meetingId, String finalJson) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = objectMapper.readValue(finalJson, Map.class);
            double confidence = toDouble(data.get("overallConfidenceScore"));
            return finalReportRepository.save(FinalReport.builder()
                    .meetingRequestId(meetingId)
                    .reportPayload(finalJson)
                    .overallConfidence(confidence)
                    .build());
        } catch (Exception e) {
            log.error("[Meeting {}] Failed to parse final synthesis JSON: {}", meetingId, e.getMessage());
            String fallback = "{\"executiveBrief\":\"Meeting preparation complete.\","
                    + "\"overallConfidenceScore\":0.5,\"confidenceScore\":0.5,\"influencedBy\":[]}";
            return finalReportRepository.save(FinalReport.builder()
                    .meetingRequestId(meetingId)
                    .reportPayload(fallback)
                    .overallConfidence(0.5)
                    .build());
        }
    }

    private MeetingSessionResponseDTO buildResponse(MeetingRequest meeting,
                                                     List<AgentRun> runs,
                                                     List<AgentTrace> traces,
                                                     FinalReport report) {
        return new MeetingSessionResponseDTO(
                meeting.getId(),
                meeting.getOrganizationName(),
                meeting.getStatus(),
                runs.stream().map(AgentRunDTO::from).collect(Collectors.toList()),
                traces.stream().map(AgentTraceDTO::from).collect(Collectors.toList()),
                report != null ? FinalReportDTO.from(report, objectMapper) : null
        );
    }

    private String wrapSummary(String summary) {
        try {
            return objectMapper.writeValueAsString(
                    Map.of("summary", summary != null ? summary : ""));
        } catch (Exception e) {
            return "{\"summary\":\"\"}";
        }
    }

    private int getOrder(String agentName) {
        return switch (agentName) {
            case "OrganizationResearchAgent" -> 1;
            case "StakeholderPersonaAgent"   -> 2;
            case "EngagementStrategyAgent"   -> 3;
            case "ObjectionPredictionAgent"  -> 4;
            case "CriticValidatorAgent"      -> 5;
            case "FinalSynthesisAgent"       -> 6;
            default -> 99;
        };
    }

    private double toDouble(Object o) {
        if (o == null) return 0.5;
        if (o instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(o.toString()); } catch (Exception e) { return 0.5; }
    }
}
