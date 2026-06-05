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

    @PostMapping
    public ResponseEntity<MeetingSessionResponseDTO> createMeeting(
            @Valid @RequestBody MeetingRequestDTO requestDTO) {
        log.info("New meeting request for: {}", requestDTO.organizationName());
        MeetingSessionResponseDTO response = orchestrationService.orchestrate(requestDTO);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/demo")
    public ResponseEntity<MeetingSessionResponseDTO> runDemo() {
        log.info("Demo mode meeting request triggered");
        MeetingRequestDTO demo = new MeetingRequestDTO(
                "Apollo Hospitals",
                "Pitch our AI-powered clinical workflow automation platform",
                "A SaaS platform that automates clinical documentation, reduces nurse workload by 40%, and integrates with existing HIS/EMR systems via HL7 FHIR APIs.",
                "CTO"
        );
        MeetingSessionResponseDTO response = orchestrationService.orchestrate(demo);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{sessionId}")
    public ResponseEntity<MeetingSessionResponseDTO> getSession(
            @PathVariable UUID sessionId) {
        return ResponseEntity.ok(orchestrationService.getSession(sessionId));
    }

    @GetMapping("/{sessionId}/traces")
    public ResponseEntity<?> getTraces(@PathVariable UUID sessionId) {
        MeetingSessionResponseDTO session = orchestrationService.getSession(sessionId);
        return ResponseEntity.ok(session.traces());
    }

    @GetMapping("/{sessionId}/report")
    public ResponseEntity<?> getReport(@PathVariable UUID sessionId) {
        MeetingSessionResponseDTO session = orchestrationService.getSession(sessionId);
        return ResponseEntity.ok(session.finalReport());
    }
}
