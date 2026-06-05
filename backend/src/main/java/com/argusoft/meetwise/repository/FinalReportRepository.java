package com.argusoft.meetwise.repository;

import com.argusoft.meetwise.entity.FinalReport;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FinalReportRepository extends JpaRepository<FinalReport, UUID> {
    Optional<FinalReport> findByMeetingRequestId(UUID meetingRequestId);
    void deleteByMeetingRequestId(UUID meetingRequestId);
}
