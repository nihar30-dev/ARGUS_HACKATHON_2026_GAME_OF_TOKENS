package com.argusoft.meetwise.service;

import com.argusoft.meetwise.dto.AuthResponseDTO;
import com.argusoft.meetwise.dto.LoginRequestDTO;
import com.argusoft.meetwise.dto.RegisterRequestDTO;
import com.argusoft.meetwise.entity.AppUser;
import com.argusoft.meetwise.entity.UserSession;
import com.argusoft.meetwise.exception.MeetwiseException;
import com.argusoft.meetwise.repository.AppUserRepository;
import com.argusoft.meetwise.repository.UserSessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final AppUserRepository userRepository;
    private final UserSessionRepository sessionRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public AuthResponseDTO register(RegisterRequestDTO dto) {
        if (userRepository.existsByEmail(dto.email())) {
            throw new MeetwiseException("Email already registered: " + dto.email());
        }
        AppUser user = userRepository.save(AppUser.builder()
                .name(dto.name())
                .email(dto.email())
                .passwordHash(passwordEncoder.encode(dto.password()))
                .build());
        log.info("[Auth] Registered user {}", user.getEmail());
        return createSession(user);
    }

    public AuthResponseDTO login(LoginRequestDTO dto) {
        AppUser user = userRepository.findByEmail(dto.email())
                .orElseThrow(() -> new MeetwiseException("Invalid email or password"));
        if (!passwordEncoder.matches(dto.password(), user.getPasswordHash())) {
            throw new MeetwiseException("Invalid email or password");
        }
        log.info("[Auth] Login for {}", user.getEmail());
        return createSession(user);
    }

    public void logout(UUID token) {
        sessionRepository.deleteById(token);
        log.info("[Auth] Session {} revoked", token);
    }

    /**
     * Validates a raw Authorization header value ("Bearer <uuid>").
     * Returns the owning AppUser if the token exists and has not expired, null otherwise.
     */
    public AppUser validateToken(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) return null;
        try {
            UUID token = UUID.fromString(authorizationHeader.substring(7).trim());
            return sessionRepository.findValidByToken(token, LocalDateTime.now())
                    .flatMap(s -> userRepository.findById(s.getUserId()))
                    .orElse(null);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private AuthResponseDTO createSession(AppUser user) {
        UUID token = UUID.randomUUID();
        sessionRepository.save(UserSession.builder()
                .token(token)
                .userId(user.getId())
                .expiresAt(LocalDateTime.now().plusDays(30))
                .build());
        return new AuthResponseDTO(token.toString(), user.getId().toString(), user.getName(), user.getEmail());
    }
}
