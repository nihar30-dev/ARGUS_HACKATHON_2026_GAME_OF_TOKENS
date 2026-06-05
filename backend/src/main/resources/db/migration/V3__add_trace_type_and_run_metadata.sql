-- V3: Enrich agent_trace and agent_runs for judge-visible Trace View
-- agent_trace gets influence_type so the UI can distinguish INFLUENCE vs VALIDATION vs REFINEMENT vs CONFLICT_RESOLUTION
-- agent_runs gets agent_type, agent_status, trace_summary, influence_summary for richer Agent Trace View cards

ALTER TABLE agent_trace
    ADD COLUMN IF NOT EXISTS influence_type VARCHAR(50) DEFAULT 'INFLUENCE';

ALTER TABLE agent_runs
    ADD COLUMN IF NOT EXISTS agent_type       VARCHAR(50),
    ADD COLUMN IF NOT EXISTS agent_status     VARCHAR(50) DEFAULT 'SUCCESS',
    ADD COLUMN IF NOT EXISTS trace_summary    TEXT,
    ADD COLUMN IF NOT EXISTS influence_summary TEXT;

CREATE INDEX IF NOT EXISTS idx_agent_trace_type ON agent_trace(meeting_request_id, influence_type);
