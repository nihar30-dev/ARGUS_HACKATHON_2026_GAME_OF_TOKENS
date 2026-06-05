package com.argusoft.meetwise.repository;

import com.argusoft.meetwise.entity.AgentTrace;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AgentTraceRepository extends JpaRepository<AgentTrace, UUID> {
    List<AgentTrace> findByMeetingRequestIdOrderByCreatedAtAsc(UUID meetingRequestId);
    void deleteByMeetingRequestId(UUID meetingRequestId);
}
