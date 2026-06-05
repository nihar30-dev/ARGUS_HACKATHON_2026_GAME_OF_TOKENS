package com.argusoft.meetwise.controller;

import com.argusoft.meetwise.dto.*;
import com.argusoft.meetwise.service.MeetingOrchestrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/meetings")
@RequiredArgsConstructor
@Slf4j
public class MeetingController {

    private final MeetingOrchestrationService orchestrationService;

    /**
     * POST /api/meetings
     * Create a meeting record. Returns 201 with the new meeting's details (status=PENDING).
     * Does NOT run agents — call /run to trigger the pipeline.
     */
    @PostMapping
    public ResponseEntity<CreateMeetingResponseDTO> createMeeting(
            @Valid @RequestBody MeetingRequestDTO dto) {
        log.info("Creating meeting for: {}", dto.organizationName());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(orchestrationService.create(dto));
    }

    /**
     * POST /api/meetings/{id}/run
     * Run the 6-agent pipeline for a PENDING meeting. Synchronous — waits for all agents.
     * Returns 400 if the meeting is not in PENDING state.
     */
    @PostMapping("/{id}/run")
    public ResponseEntity<MeetingSessionResponseDTO> runAgents(@PathVariable UUID id) {
        log.info("Running agent pipeline for meeting: {}", id);
        return ResponseEntity.ok(orchestrationService.runPipeline(id));
    }

    /**
     * GET /api/meetings/demo
     * Return the pre-seeded Apollo Hospitals demo session.
     * Always succeeds — no Gemini dependency. Use when live API quota is exhausted.
     * NOTE: this mapping must appear before GET /{id} so Spring routes /demo literally.
     */
    @GetMapping("/demo")
    public ResponseEntity<MeetingSessionResponseDTO> getDemo() {
        log.info("Demo session requested");
        return ResponseEntity.ok(orchestrationService.getDemoSession());
    }

    /**
     * GET /api/meetings/{id}
     * Full session details: meeting metadata, all agent runs, all trace rows, final report.
     * Returns 404 if the meeting does not exist.
     */
    @GetMapping("/{id}")
    public ResponseEntity<MeetingSessionResponseDTO> getSession(@PathVariable UUID id) {
        return ResponseEntity.ok(orchestrationService.getSession(id));
    }

    /**
     * GET /api/meetings/{id}/trace
     * Agent trace rows for the Agent Trace View screen.
     * Returns 404 if the meeting does not exist.
     */
    @GetMapping("/{id}/trace")
    public ResponseEntity<List<AgentTraceDTO>> getTrace(@PathVariable UUID id) {
        return ResponseEntity.ok(orchestrationService.getTraces(id));
    }

    /**
     * GET /api/meetings/{id}/report
     * Final synthesis report only.
     * Returns 404 if the meeting does not exist or agents have not completed yet.
     */
    @GetMapping("/{id}/report")
    public ResponseEntity<FinalReportDTO> getReport(@PathVariable UUID id) {
        return ResponseEntity.ok(orchestrationService.getReport(id));
    }
}
