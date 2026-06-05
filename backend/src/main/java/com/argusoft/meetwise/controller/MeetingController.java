package com.argusoft.meetwise.controller;

import com.argusoft.meetwise.dto.*;
import com.argusoft.meetwise.service.MeetingOrchestrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/meetings")
@RequiredArgsConstructor
@Slf4j
public class MeetingController {

    private final MeetingOrchestrationService orchestrationService;

    /** Start a new pipeline — returns immediately with meetingRequestId. */
    @PostMapping
    public ResponseEntity<MeetingStartResponseDTO> createMeeting(
            @Valid @RequestBody MeetingRequestDTO requestDTO) {
        log.info("New meeting request for: {}", requestDTO.organizationName());
        return ResponseEntity.ok(orchestrationService.orchestrate(requestDTO));
    }

    /** Re-run pipeline on an existing meeting request. */
    @PostMapping("/{meetingId}/run")
    public ResponseEntity<MeetingStartResponseDTO> runExisting(@PathVariable UUID meetingId) {
        log.info("Re-run pipeline for meeting: {}", meetingId);
        return ResponseEntity.ok(orchestrationService.runById(meetingId));
    }

    /** Apollo Hospitals demo — starts async, returns immediately. */
    @PostMapping("/demo")
    public ResponseEntity<MeetingStartResponseDTO> runDemo() {
        log.info("Demo pipeline triggered");
        MeetingRequestDTO demo = new MeetingRequestDTO(
                "Apollo Hospitals",
                "Discuss MEDplat digital health platform partnership",
                "MEDplat is a digital health platform connecting patients, doctors, and hospitals through AI-powered diagnostics, telemedicine, and clinical workflow automation via HL7 FHIR APIs.",
                "CEO"
        );
        return ResponseEntity.ok(orchestrationService.orchestrate(demo));
    }

    /** Full session with agent runs, traces, and report — available after pipeline completes. */
    @GetMapping("/{meetingId}")
    public ResponseEntity<MeetingSessionResponseDTO> getSession(@PathVariable UUID meetingId) {
        return ResponseEntity.ok(orchestrationService.getSession(meetingId));
    }

    /** Agent influence trace edges only. */
    @GetMapping("/{meetingId}/traces")
    public ResponseEntity<?> getTraces(@PathVariable UUID meetingId) {
        return ResponseEntity.ok(orchestrationService.getSession(meetingId).traces());
    }

    /** Final synthesis report — 404 if not ready yet. */
    @GetMapping("/{meetingId}/report")
    public ResponseEntity<?> getReport(@PathVariable UUID meetingId) {
        var report = orchestrationService.getSession(meetingId).finalReport();
        if (report == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(report);
    }
}
