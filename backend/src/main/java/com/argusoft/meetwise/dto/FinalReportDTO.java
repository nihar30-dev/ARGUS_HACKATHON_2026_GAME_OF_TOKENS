package com.argusoft.meetwise.dto;

import com.argusoft.meetwise.entity.FinalReport;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

public record FinalReportDTO(
        UUID id,
        UUID meetingRequestId,
        String executiveBrief,
        String conversationFlowJson,
        String questionsJson,
        String objectionResponsesJson,
        String nextStepsJson,
        double overallConfidence,
        LocalDateTime createdAt
) {
    // Parses the JSONB report_payload and exposes structured fields for the Flutter client
    @SuppressWarnings("unchecked")
    public static FinalReportDTO from(FinalReport report, ObjectMapper mapper) {
        try {
            Map<String, Object> data = mapper.readValue(report.getReportPayload(), Map.class);
            return new FinalReportDTO(
                    report.getId(),
                    report.getMeetingRequestId(),
                    str(data.get("executiveBrief")),
                    mapper.writeValueAsString(data.get("conversationFlow")),
                    mapper.writeValueAsString(data.get("topQuestions")),
                    mapper.writeValueAsString(data.get("objectionResponses")),
                    mapper.writeValueAsString(data.get("nextSteps")),
                    toDouble(data.get("overallConfidenceScore")),
                    report.getCreatedAt()
            );
        } catch (Exception e) {
            return new FinalReportDTO(
                    report.getId(), report.getMeetingRequestId(),
                    "Meeting preparation complete. See agent outputs for details.",
                    null, null, null, null,
                    report.getOverallConfidence(), report.getCreatedAt()
            );
        }
    }

    private static String str(Object o) { return o == null ? null : o.toString(); }

    private static double toDouble(Object o) {
        if (o == null) return 0.5;
        if (o instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(o.toString()); } catch (Exception e) { return 0.5; }
    }
}
