package com.argusoft.meetwise.dto;

import java.util.List;

public record KnowledgeSearchResponse(
        String                  query,
        int                     totalFound,
        List<KnowledgeChunkDto> chunks
) {}
