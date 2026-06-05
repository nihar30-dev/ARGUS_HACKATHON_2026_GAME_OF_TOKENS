package com.argusoft.meetwise.service;

import com.argusoft.meetwise.agent.Agent;
import com.argusoft.meetwise.agent.AgentContext;
import com.argusoft.meetwise.agent.AgentOutput;
import com.argusoft.meetwise.dto.*;
import com.argusoft.meetwise.entity.*;
import com.argusoft.meetwise.exception.MeetwiseException;
import com.argusoft.meetwise.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MeetingOrchestrationService {

    private final List<Agent> agents;
    private final MeetingRequestRepository meetingRequestRepository;
    private final AgentRunRepository agentRunRepository;
    private final AgentTraceRepository agentTraceRepository;
    private final FinalReportRepository finalReportRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public MeetingSessionResponseDTO orchestrate(MeetingRequestDTO dto) {
        UUID sessionId = UUID.randomUUID();

        MeetingRequest meeting = meetingRequestRepository.save(MeetingRequest.builder()
                .sessionId(sessionId)
                .organizationName(dto.organizationName())
                .meetingObjective(dto.meetingObjective())
                .offeringDescription(dto.offeringDescription())
                .stakeholderRole(dto.stakeholderRole())
                .status("RUNNING")
                .build());

        AgentContext context = new AgentContext(meeting);
        List<AgentRun> runs = new ArrayList<>();
        List<AgentTrace> traces = new ArrayList<>();

        List<Agent> pipeline = agents.stream()
                .sorted(Comparator.comparingInt(Agent::getOrder))
                .collect(Collectors.toList());

        try {
            for (Agent agent : pipeline) {
                log.info("[Session {}] Running {} (order {})", sessionId, agent.getName(), agent.getOrder());
                long start = System.currentTimeMillis();

                AgentOutput output = agent.execute(context);
                long executionMs = System.currentTimeMillis() - start;

                context.putOutput(agent.getName(), output.getOutputJson());

                AgentRun run = agentRunRepository.save(toAgentRun(sessionId, output, executionMs));
                runs.add(run);

                List<AgentTrace> agentTraces = buildTraces(sessionId, output);
                traces.addAll(agentTraceRepository.saveAll(agentTraces));

                log.info("[Session {}] {} completed in {}ms, confidence={}", sessionId,
                        agent.getName(), executionMs, output.getConfidenceScore());
            }

            meeting.setStatus("COMPLETED");
            meetingRequestRepository.save(meeting);

            FinalReport report = saveFinalReport(sessionId, meeting.getId(),
                    context.getOutput("FinalSynthesisAgent"));

            return buildResponse(sessionId, meeting, runs, traces, report);

        } catch (Exception e) {
            log.error("[Session {}] Orchestration failed: {}", sessionId, e.getMessage(), e);
            meeting.setStatus("FAILED");
            meetingRequestRepository.save(meeting);
            throw new MeetwiseException("Orchestration failed: " + e.getMessage(), e);
        }
    }

    public MeetingSessionResponseDTO getSession(UUID sessionId) {
        MeetingRequest meeting = meetingRequestRepository.findBySessionId(sessionId)
                .orElseThrow(() -> new MeetwiseException("Session not found: " + sessionId));
        List<AgentRun> runs = agentRunRepository.findBySessionIdOrderByExecutionOrderIndexAsc(sessionId);
        List<AgentTrace> traces = agentTraceRepository.findBySessionIdOrderByTimestampAsc(sessionId);
        FinalReport report = finalReportRepository.findBySessionId(sessionId).orElse(null);
        return buildResponse(sessionId, meeting, runs, traces, report);
    }

    private AgentRun toAgentRun(UUID sessionId, AgentOutput output, long executionMs) {
        return AgentRun.builder()
                .sessionId(sessionId)
                .agentName(output.getAgentName())
                .executionOrderIndex(getOrder(output.getAgentName()))
                .inputJson(output.getInputSummary())
                .outputJson(output.getOutputJson())
                .confidenceScore(output.getConfidenceScore())
                .influencedBy(output.getInfluencedBy() == null ? ""
                        : String.join(",", output.getInfluencedBy()))
                .usedGemini(output.isUsedGemini())
                .executionMs(executionMs)
                .build();
    }

    private List<AgentTrace> buildTraces(UUID sessionId, AgentOutput output) {
        if (output.getInfluencedBy() == null) return List.of();
        return output.getInfluencedBy().stream()
                .map(source -> AgentTrace.builder()
                        .sessionId(sessionId)
                        .sourceAgent(source)
                        .targetAgent(output.getAgentName())
                        .inputSummary(output.getInputSummary())
                        .outputSummary(output.getOutputSummary())
                        .influenceDescription(source + " output provided context that shaped "
                                + output.getAgentName() + "'s analysis and output")
                        .timestamp(LocalDateTime.now())
                        .build())
                .collect(Collectors.toList());
    }

    private FinalReport saveFinalReport(UUID sessionId, UUID meetingId, String finalJson) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = objectMapper.readValue(finalJson, Map.class);
            return finalReportRepository.save(FinalReport.builder()
                    .sessionId(sessionId)
                    .meetingRequestId(meetingId)
                    .executiveBrief(str(data.get("executiveBrief")))
                    .conversationFlowJson(toJson(data.get("conversationFlow")))
                    .questionsJson(toJson(data.get("topQuestions")))
                    .objectionResponsesJson(toJson(data.get("objectionResponses")))
                    .nextStepsJson(toJson(data.get("nextSteps")))
                    .overallConfidence(toDouble(data.get("overallConfidenceScore")))
                    .build());
        } catch (Exception e) {
            log.error("Failed to parse final synthesis JSON: {}", e.getMessage());
            return finalReportRepository.save(FinalReport.builder()
                    .sessionId(sessionId)
                    .meetingRequestId(meetingId)
                    .executiveBrief("Meeting preparation completed. See agent outputs for full details.")
                    .overallConfidence(0.5)
                    .build());
        }
    }

    private MeetingSessionResponseDTO buildResponse(UUID sessionId, MeetingRequest meeting,
                                                     List<AgentRun> runs, List<AgentTrace> traces,
                                                     FinalReport report) {
        return new MeetingSessionResponseDTO(
                sessionId,
                meeting.getId(),
                meeting.getOrganizationName(),
                meeting.getStatus(),
                runs.stream().map(AgentRunDTO::from).collect(Collectors.toList()),
                traces.stream().map(AgentTraceDTO::from).collect(Collectors.toList()),
                report != null ? FinalReportDTO.from(report) : null
        );
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

    private String str(Object o) { return o == null ? null : o.toString(); }

    private double toDouble(Object o) {
        if (o == null) return 0.5;
        if (o instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(o.toString()); } catch (Exception e) { return 0.5; }
    }

    private String toJson(Object o) {
        if (o == null) return null;
        try { return objectMapper.writeValueAsString(o); } catch (Exception e) { return null; }
    }
}
