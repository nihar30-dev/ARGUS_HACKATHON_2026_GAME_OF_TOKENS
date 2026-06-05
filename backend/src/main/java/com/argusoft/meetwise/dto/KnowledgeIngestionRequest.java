package com.argusoft.meetwise.dto;

import jakarta.validation.constraints.NotBlank;

public record KnowledgeIngestionRequest(
        @NotBlank String title,
        @NotBlank String sourceType,
                  String sourceName,
        @NotBlank String text,
                  String metadata
) {}
