package com.argusoft.meetwise.dto;

import java.util.UUID;

public record AuthResponseDTO(
        String token,
        String userId,
        String name,
        String email
) {}
