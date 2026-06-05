package com.argusoft.meetwise.controller;

import com.argusoft.meetwise.dto.AuthResponseDTO;
import com.argusoft.meetwise.dto.LoginRequestDTO;
import com.argusoft.meetwise.dto.RegisterRequestDTO;
import com.argusoft.meetwise.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /** POST /api/auth/register — creates account + returns session token */
    @PostMapping("/register")
    public ResponseEntity<AuthResponseDTO> register(@Valid @RequestBody RegisterRequestDTO dto) {
        return ResponseEntity.ok(authService.register(dto));
    }

    /** POST /api/auth/login — validates credentials + returns session token */
    @PostMapping("/login")
    public ResponseEntity<AuthResponseDTO> login(@Valid @RequestBody LoginRequestDTO dto) {
        return ResponseEntity.ok(authService.login(dto));
    }

    /** POST /api/auth/logout — invalidates the current session token */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                UUID token = UUID.fromString(header.substring(7).trim());
                authService.logout(token);
            } catch (IllegalArgumentException ignored) {}
        }
        return ResponseEntity.ok(Map.of("status", "logged out"));
    }
}
