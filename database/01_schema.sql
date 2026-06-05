-- MeetWise Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS meeting_requests (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id    UUID,
    organization_name   VARCHAR(255) NOT NULL,
    meeting_objective   TEXT NOT NULL,
    offering_description TEXT NOT NULL,
    stakeholder_role    VARCHAR(255) NOT NULL,
    status        VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agent_runs (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id            UUID NOT NULL,
    agent_name            VARCHAR(100) NOT NULL,
    execution_order_index INT NOT NULL,
    input_json            TEXT,
    output_json           TEXT NOT NULL,
    confidence_score      NUMERIC(4,3) NOT NULL DEFAULT 0.0,
    influenced_by         TEXT,
    used_gemini           BOOLEAN NOT NULL DEFAULT FALSE,
    execution_ms          BIGINT NOT NULL DEFAULT 0,
    executed_at           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agent_trace (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id           UUID NOT NULL,
    source_agent         VARCHAR(100) NOT NULL,
    target_agent         VARCHAR(100) NOT NULL,
    input_summary        TEXT,
    output_summary       TEXT,
    influence_description TEXT,
    timestamp            TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS final_reports (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id            UUID NOT NULL UNIQUE,
    meeting_request_id    UUID NOT NULL,
    executive_brief       TEXT,
    conversation_flow_json TEXT,
    questions_json        TEXT,
    objection_responses_json TEXT,
    next_steps_json       TEXT,
    overall_confidence    NUMERIC(4,3) NOT NULL DEFAULT 0.0,
    generated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_agent_runs_session ON agent_runs(session_id);
CREATE INDEX IF NOT EXISTS idx_agent_runs_agent_name ON agent_runs(session_id, agent_name);
CREATE INDEX IF NOT EXISTS idx_agent_trace_session ON agent_trace(session_id);
CREATE INDEX IF NOT EXISTS idx_agent_trace_source ON agent_trace(session_id, source_agent);
CREATE INDEX IF NOT EXISTS idx_final_reports_session ON final_reports(session_id);
CREATE INDEX IF NOT EXISTS idx_meeting_requests_status ON meeting_requests(status);
