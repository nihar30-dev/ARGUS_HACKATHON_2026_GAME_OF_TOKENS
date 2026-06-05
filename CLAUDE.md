# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MeetWise is a hybrid multi-agent meeting preparation assistant for the ARGUS Hackathon 2026. Six specialized agents collaborate in sequence — each reading prior agents' outputs — to produce a meeting strategy. The hackathon judging criterion is **Agent Trace View**: visible proof that agents influenced one another.

## Stack

- **Backend:** Java 21, Spring Boot 3.2.5, Maven — package `com.argusoft.meetwise`
- **Frontend:** Flutter (Dart), Material 3
- **Database:** PostgreSQL — 4 tables: `meeting_requests`, `agent_runs`, `agent_trace`, `final_reports`
- **LLM:** Gemini 2.5 Flash via REST (`gemini.api.url` in `application.properties`)

## Commands

**Backend:**
```bash
cd backend
mvn spring-boot:run                        # start on :8080
mvn test                                   # run tests
mvn clean package -DskipTests             # build JAR
```

**Frontend:**
```bash
cd frontend
flutter pub get
flutter run                                # connects to localhost:8080
```

**Database:**
```bash
psql -U postgres -c "CREATE DATABASE meetwise;"
psql -U postgres -d meetwise -f database/01_schema.sql
psql -U postgres -d meetwise -f database/02_seed_demo.sql   # Apollo Hospitals demo data
```

**Quick demo test (no Gemini needed):**
```bash
curl -X POST http://localhost:8080/api/meetings/demo
```

## Agent Architecture

Six agents run sequentially. Each is a Spring `@Component` implementing `Agent`. The orchestrator auto-discovers and sorts them by `getOrder()`.

| Order | Agent | Type | Reads From |
|---|---|---|---|
| 1 | `OrganizationResearchAgent` | Gemini | — |
| 2 | `StakeholderPersonaAgent` | Rule-based | Research |
| 3 | `EngagementStrategyAgent` | Gemini | Research + Persona |
| 4 | `ObjectionPredictionAgent` | Gemini | Research + Persona + Strategy |
| 5 | `CriticValidatorAgent` | Rule-based | All 4 above |
| 6 | `FinalSynthesisAgent` | Gemini | All 5 above |

**Adding a new agent:** Implement `Agent`, annotate `@Component`, set a unique `getOrder()` — nothing else changes.

## Key Design Rules

- Every agent output JSON must include `confidenceScore` and `influencedBy[]`.
- Every agent writes one `AgentTrace` row per source in `influencedBy[]` — this powers the Trace View.
- Gemini agents (1, 3, 4, 6) must catch exceptions and fall back to `classpath:sample-data/*_fallback.json`.
- Rule-based agents (2, 5) never call Gemini.
- `DEMO_MODE=true` skips all Gemini calls without changing agent logic.
- Gemini config: `temperature=0.3`, `maxOutputTokens=1000`, `responseMimeType=application/json`.

## Environment Variables

| Variable | Default | Notes |
|---|---|---|
| `GEMINI_API_KEY` | (required for live) | Not needed when `DEMO_MODE=true` |
| `DB_URL` | `jdbc:postgresql://localhost:5432/meetwise` | |
| `DB_USERNAME` | `postgres` | |
| `DB_PASSWORD` | `postgres` | |
| `DEMO_MODE` | `false` | `true` = use fallback JSONs |

## API Endpoints

- `POST /api/meetings` — run full pipeline, returns `MeetingSessionResponseDTO`
- `POST /api/meetings/demo` — Apollo Hospitals demo (no Gemini)
- `GET /api/meetings/{sessionId}` — load stored session
- `GET /api/meetings/{sessionId}/traces` — just the trace records
- `GET /api/meetings/{sessionId}/report` — just the final report

## Highest Scoring Feature

The **Agent Trace View** (`agent_trace_screen.dart`) must show directional arrows from source → target agents with `influenceDescription` text. The `CriticValidatorAgent` finding issues that were then incorporated by `FinalSynthesisAgent` is the key story to demonstrate to judges.
