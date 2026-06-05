package com.argusoft.meetwise.dto;

import com.argusoft.meetwise.entity.FinalReport;

import java.time.LocalDateTime;
import java.util.UUID;

public record FinalReportDTO(
        UUID id,
        UUID sessionId,
        String executiveBrief,
        String conversationFlowJson,
        String questionsJson,
        String objectionResponsesJson,
        String nextStepsJson,
        double overallConfidence,
        LocalDateTime generatedAt
) {
    public static FinalReportDTO from(FinalReport report) {
        return new FinalReportDTO(
                report.getId(), report.getSessionId(),
                report.getExecutiveBrief(), report.getConversationFlowJson(),
                report.getQuestionsJson(), report.getObjectionResponsesJson(),
                report.getNextStepsJson(), report.getOverallConfidence(),
                report.getGeneratedAt()
        );
    }
}
