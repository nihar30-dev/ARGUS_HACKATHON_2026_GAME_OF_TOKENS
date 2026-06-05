# MeetWise — Architecture

## Pipeline

```
POST /api/meetings
       │
       ▼
MeetingOrchestrationService
       │
       ├─▶ [1] OrganizationResearchAgent   (Gemini)  → saves AgentRun + AgentTrace[]
       ├─▶ [2] StakeholderPersonaAgent     (Rules)   → saves AgentRun + AgentTrace[]
       ├─▶ [3] EngagementStrategyAgent     (Gemini)  → saves AgentRun + AgentTrace[]
       ├─▶ [4] ObjectionPredictionAgent    (Gemini)  → saves AgentRun + AgentTrace[]
       ├─▶ [5] CriticValidatorAgent        (Rules)   → saves AgentRun + AgentTrace[]
       └─▶ [6] FinalSynthesisAgent         (Gemini)  → saves AgentRun + AgentTrace[]
                                                            │
                                                            ▼
                                                      FinalReport saved
                                                            │
                                                            ▼
                                               MeetingSessionResponseDTO returned
```

## Agent Context Pattern

`AgentContext` is a shared state object passed through the pipeline. Each agent reads previous agents' outputs via `context.getOutput("AgentName")` and writes its own via `context.putOutput(name, json)`. Agents cannot skip ahead — the sequential write order enforces the dependency graph.

## Traceability Model

Every agent that reads from a prior agent records one `AgentTrace` row per source:

| source_agent | target_agent | influence_description |
|---|---|---|
| OrganizationResearchAgent | StakeholderPersonaAgent | Research identified Astreya HIS... |
| StakeholderPersonaAgent | EngagementStrategyAgent | CTO technical style shaped opening... |
| ObjectionPredictionAgent | CriticValidatorAgent | Critic validated top objections... |
| CriticValidatorAgent | FinalSynthesisAgent | Critic improvements applied to brief |

The Flutter Agent Trace View queries `/api/meetings/{sessionId}/traces` and renders these as directional arrows between agent cards.

## Gemini Integration

`GeminiService` calls the `gemini-2.5-flash` REST API. Configuration:
- `temperature: 0.3` — deterministic enough for business strategy
- `maxOutputTokens: 1000` — credit-efficient
- `responseMimeType: application/json` — guarantees parseable output

Every Gemini agent wraps the call in try/catch. On failure: load the fallback JSON from `classpath:sample-data/`, log a warning, set `confidence: 0.1`, and continue. The pipeline never crashes on a Gemini failure.

## Demo Mode

Set `DEMO_MODE=true` or use `POST /api/meetings/demo`. All Gemini agents skip the API call and load their fallback JSONs. The rule-based agents (Persona, Critic) still execute their real logic. The complete pipeline runs in < 100ms.

## Database

4 tables, UUID primary keys, PostgreSQL.

```
meeting_requests  — one row per user request, tracks status
agent_runs        — one row per agent execution, stores full input/output JSON
agent_trace       — one row per agent influence connection (source → target)
final_reports     — parsed final synthesis stored in structured columns
```

## Frontend Screens

1. **Meeting Input** — form + demo button, shows agent pipeline preview
2. **Agent Dashboard** — card per agent with confidence bar, influenced-by chips, expandable raw JSON
3. **Agent Trace View** — split panel: pipeline column with confidence bars + detail panel with inbound/outbound trace cards
4. **Final Report** — conversation flow timeline, questions, objection response cards, next steps
