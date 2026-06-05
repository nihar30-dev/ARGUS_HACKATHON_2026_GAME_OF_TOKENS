package com.argusoft.meetwise.repository;

import com.argusoft.meetwise.entity.MeetingRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MeetingRequestRepository extends JpaRepository<MeetingRequest, UUID> {
    List<MeetingRequest> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
