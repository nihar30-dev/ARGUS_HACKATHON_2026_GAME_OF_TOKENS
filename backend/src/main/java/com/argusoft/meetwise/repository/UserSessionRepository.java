package com.argusoft.meetwise.repository;

import com.argusoft.meetwise.entity.UserSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface UserSessionRepository extends JpaRepository<UserSession, UUID> {

    @Query("SELECT s FROM UserSession s WHERE s.token = :token AND s.expiresAt > :now")
    Optional<UserSession> findValidByToken(@Param("token") UUID token, @Param("now") LocalDateTime now);
}
