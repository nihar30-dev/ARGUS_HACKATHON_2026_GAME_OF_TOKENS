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
        return ResponseEntity.ok(orchestrationService.orchestrate(requestDTO));
    }

    @PostMapping("/demo")
    public ResponseEntity<MeetingSessionResponseDTO> runDemo() {
        log.info("Demo mode triggered");
        MeetingRequestDTO demo = new MeetingRequestDTO(
                "Apollo Hospitals",
                "Discuss MEDplat digital health platform partnership",
                "MEDplat is a digital health platform connecting patients, doctors, and hospitals through AI-powered diagnostics, telemedicine, and clinical workflow automation via HL7 FHIR APIs.",
                "CEO"
        );
        return ResponseEntity.ok(orchestrationService.orchestrate(demo));
    }

    @GetMapping("/{meetingId}")
    public ResponseEntity<MeetingSessionResponseDTO> getSession(@PathVariable UUID meetingId) {
        return ResponseEntity.ok(orchestrationService.getSession(meetingId));
    }

    @GetMapping("/{meetingId}/traces")
    public ResponseEntity<?> getTraces(@PathVariable UUID meetingId) {
        return ResponseEntity.ok(orchestrationService.getSession(meetingId).traces());
    }

    @GetMapping("/{meetingId}/report")
    public ResponseEntity<?> getReport(@PathVariable UUID meetingId) {
        return ResponseEntity.ok(orchestrationService.getSession(meetingId).finalReport());
    }
}
