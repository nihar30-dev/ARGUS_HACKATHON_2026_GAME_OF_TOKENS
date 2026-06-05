# MeetWise — Multi-Agent Meeting Preparation Assistant

MeetWise orchestrates six specialized AI agents that collaborate, challenge each other, and produce a superior meeting preparation strategy. Built for ARGUS Hackathon 2026.

## What Makes It Different

Unlike a single LLM prompt, MeetWise shows **how agents influence one another**: the Objection agent challenges the Strategy agent, the Critic agent validates all outputs, and the Final agent synthesises everything — including critic feedback. Every influence relationship is stored and visualised in the Agent Trace View.

## Architecture

```
User Input
  → Organization Research Agent   (Gemini)
  → Stakeholder Persona Agent     (Rule-based Java)
  → Engagement Strategy Agent     (Gemini)
  → Objection Prediction Agent    (Gemini)
  → Critic Validator Agent        (Rule-based Java)
  → Final Synthesis Agent         (Gemini)
```

Each agent emits `confidenceScore` and `influencedBy[]`. Every agent-to-agent relationship is stored as an `AgentTrace` record and rendered as directional arrows in the UI.

## Running the Backend

```bash
cd backend
cp src/main/resources/application.properties.example src/main/resources/application.properties
# Edit application.properties and set GEMINI_API_KEY
mvn spring-boot:run
# API available at http://localhost:8080
```

## Running the Frontend

```bash
cd frontend
flutter pub get
flutter run
# Connects to http://localhost:8080 by default
```

## Setting Up the Database

```bash
psql -U postgres -c "CREATE DATABASE meetwise;"
psql -U postgres -d meetwise -f database/01_schema.sql
psql -U postgres -d meetwise -f database/02_seed_demo.sql
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `GEMINI_API_KEY` | Google AI Studio API key | required |
| `DB_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/meetwise` |
| `DB_USERNAME` | Database username | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `DEMO_MODE` | Use fallback JSON instead of Gemini | `false` |

## API Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/api/meetings` | Run full agent pipeline, returns session |
| POST | `/api/meetings/demo` | Demo mode with Apollo Hospitals data |
| GET | `/api/meetings/{sessionId}` | Get stored session results |
| GET | `/api/meetings/{sessionId}/traces` | Get agent trace records |
| GET | `/api/meetings/{sessionId}/report` | Get final report only |

## Demo Scenario (Apollo Hospitals)

The built-in demo requires no Gemini credits. It uses pre-loaded fallback responses for the Apollo Hospitals scenario — a healthcare SaaS pitch to the CTO — and shows the full trace visualisation.

Run it via the **Demo Mode** button in the app, or call `POST /api/meetings/demo`.

## Project Structure

```
/backend        Java 21 Spring Boot 3 — agent pipeline, REST API
/frontend       Flutter Material 3 — 4 screens including Agent Trace View
/database       PostgreSQL schema and seed scripts
/sample-data    Fallback JSON responses for demo mode
/docs           Architecture diagram and demo notes
```
