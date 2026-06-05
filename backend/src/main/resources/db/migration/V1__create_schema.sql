-- MeetWise schema — Flyway V1
-- JSONB payloads for agent I/O, FK constraints from all child tables to meeting_requests

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────
-- 1. meeting_requests
--    Root of every pipeline run. id IS the session identifier.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS meeting_requests (
    id                   UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_name    VARCHAR(255) NOT NULL,
    stakeholder_role     VARCHAR(255) NOT NULL,
    meeting_objective    TEXT         NOT NULL,
    offering_description TEXT         NOT NULL,
    status               VARCHAR(50)  NOT NULL DEFAULT 'PENDING',
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 2. agent_runs
--    One row per agent execution per meeting.
--    input_payload / output_payload are JSONB so judges can query them.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS agent_runs (
    id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_request_id  UUID        NOT NULL
                            REFERENCES meeting_requests(id) ON DELETE CASCADE,
    agent_name          VARCHAR(100) NOT NULL,
    execution_order     INT          NOT NULL,
    input_payload       JSONB,
    output_payload      JSONB        NOT NULL,
    confidence_score    NUMERIC(4,3) NOT NULL DEFAULT 0.000,
    influenced_by       TEXT,
    used_gemini         BOOLEAN      NOT NULL DEFAULT FALSE,
    execution_ms        BIGINT       NOT NULL DEFAULT 0,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 3. agent_trace
--    One row per directed influence edge (source → target).
--    This is what the Trace View renders as arrows.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS agent_trace (
    id                   UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_request_id   UUID        NOT NULL
                             REFERENCES meeting_requests(id) ON DELETE CASCADE,
    source_agent         VARCHAR(100) NOT NULL,
    target_agent         VARCHAR(100) NOT NULL,
    input_summary        TEXT,
    output_summary       TEXT,
    influence_description TEXT,
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 4. final_reports
--    One row per meeting (UNIQUE FK). Stores the full synthesis as JSONB
--    so downstream tools can query any field without a schema change.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS final_reports (
    id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_request_id  UUID        NOT NULL UNIQUE
                            REFERENCES meeting_requests(id) ON DELETE CASCADE,
    report_payload      JSONB        NOT NULL,
    overall_confidence  NUMERIC(4,3) NOT NULL DEFAULT 0.000,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- Indexes
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_agent_runs_meeting     ON agent_runs(meeting_request_id);
CREATE INDEX IF NOT EXISTS idx_agent_runs_order       ON agent_runs(meeting_request_id, execution_order);
CREATE INDEX IF NOT EXISTS idx_agent_trace_meeting    ON agent_trace(meeting_request_id);
CREATE INDEX IF NOT EXISTS idx_agent_trace_source     ON agent_trace(meeting_request_id, source_agent);
CREATE INDEX IF NOT EXISTS idx_final_reports_meeting  ON final_reports(meeting_request_id);
CREATE INDEX IF NOT EXISTS idx_meeting_requests_status ON meeting_requests(status);

-- GIN indexes for JSONB querying
CREATE INDEX IF NOT EXISTS idx_agent_runs_output_gin  ON agent_runs USING gin(output_payload);
CREATE INDEX IF NOT EXISTS idx_final_reports_payload_gin ON final_reports USING gin(report_payload);
