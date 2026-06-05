package com.argusoft.meetwise.controller;

import com.argusoft.meetwise.dto.UserMeetingDTO;
import com.argusoft.meetwise.entity.AppUser;
import com.argusoft.meetwise.repository.FinalReportRepository;
import com.argusoft.meetwise.repository.MeetingRequestRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final MeetingRequestRepository meetingRequestRepository;
    private final FinalReportRepository finalReportRepository;

    /** GET /api/users/me — current user's profile (requires Bearer token) */
    @GetMapping("/me")
    public ResponseEntity<?> getMe(HttpServletRequest request) {
        AppUser user = currentUser(request);
        if (user == null) return ResponseEntity.status(401).body(Map.of("error", "Unauthorized"));
        return ResponseEntity.ok(Map.of(
                "userId", user.getId().toString(),
                "name", user.getName(),
                "email", user.getEmail()
        ));
    }

    /** GET /api/users/me/meetings — all meetings created by the current user */
    @GetMapping("/me/meetings")
    public ResponseEntity<?> getMyMeetings(HttpServletRequest request) {
        AppUser user = currentUser(request);
        if (user == null) return ResponseEntity.status(401).body(Map.of("error", "Unauthorized"));

        List<UserMeetingDTO> dtos = meetingRequestRepository
                .findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(m -> {
                    var report = finalReportRepository.findByMeetingRequestId(m.getId()).orElse(null);
                    return new UserMeetingDTO(
                            m.getId(),
                            m.getOrganizationName(),
                            m.getMeetingObjective(),
                            m.getStakeholderRole(),
                            m.getStatus(),
                            m.getCreatedAt(),
                            report != null ? report.getOverallConfidence() : null
                    );
                })
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    private AppUser currentUser(HttpServletRequest request) {
        return (AppUser) request.getAttribute("currentUser");
    }
}
