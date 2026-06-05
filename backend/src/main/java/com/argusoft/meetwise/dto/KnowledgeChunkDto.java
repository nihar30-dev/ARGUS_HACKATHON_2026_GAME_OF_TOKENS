package com.argusoft.meetwise.dto;

import java.util.UUID;

public record KnowledgeChunkDto(
        UUID   id,
        String title,
        String sourceType,
        String sourceName,
        String chunkText,
        double similarity,
        String metadata
) {}
