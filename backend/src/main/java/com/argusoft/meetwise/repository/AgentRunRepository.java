package com.argusoft.meetwise.repository;

import com.argusoft.meetwise.entity.AgentRun;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AgentRunRepository extends JpaRepository<AgentRun, UUID> {
    List<AgentRun> findByMeetingRequestIdOrderByExecutionOrderAsc(UUID meetingRequestId);
    void deleteByMeetingRequestId(UUID meetingRequestId);
}
