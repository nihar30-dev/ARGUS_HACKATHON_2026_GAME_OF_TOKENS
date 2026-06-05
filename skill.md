# MeetWise — Multi-Agent Meeting Preparation Assistant

## Purpose

MeetWise prepares users for high-stakes business meetings by orchestrating six specialized AI agents that collaborate, challenge each other, and collectively produce a superior meeting strategy.

Built for **ARGUS Hackathon 2026**. Judging focuses on:

- Agent Collaboration
- Agent Orchestration
- Agent Interdependency
- Traceability
- Final Decision Quality

The goal is NOT a single AI response. The goal is to demonstrate how multiple specialized agents influence one another and collectively produce a result no single agent could.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter, Dart, Material 3 |
| Backend | Java 21, Spring Boot 3 |
| Database | PostgreSQL |
| LLM | Gemini 2.5 Flash |

---

## Architecture Principles

1. Clean Architecture — layers do not reach across boundaries
2. SOLID — each agent, service, and widget has one responsibility
3. Modular Agent Design — add agents by implementing one interface
4. Traceability — every agent influence is recorded and visualized
5. Extensibility — future teams can extend without touching existing code

---

## Agent Pipeline

Agents run in order. Each reads all prior outputs.

| # | Agent | Type | Key Output |
|---|---|---|---|
| 1 | Organization Research | Gemini | org summary, pain points, opportunities |
| 2 | Stakeholder Persona | Rule-based | priorities, communication style, decision lens |
| 3 | Engagement Strategy | Gemini | meeting goal, positioning, value proposition |
| 4 | Objection Prediction | Gemini | objections, risks, counter-responses |
| 5 | Critic Validator | Rule-based | contradictions, unsupported assumptions |
| 6 | Final Synthesis | Gemini | executive brief, conversation flow, questions, next steps |

Every agent output JSON must contain:
```json
{
  "agent": "AgentName",
  "influencedBy": ["PreviousAgent1", "PreviousAgent2"],
  "confidenceScore": 0.84
}
```

---

## Traceability Rules

Every agent execution writes an `AgentTrace` record:

| Field | Description |
|---|---|
| `sourceAgent` | Agent that produced the influence |
| `targetAgent` | Agent that consumed it |
| `inputSummary` | What the target received |
| `outputSummary` | What the target produced |
| `influenceDescription` | Human-readable description of the influence |
| `timestamp` | Execution time |

Traceability is mandatory. The UI must visualize it.

---

## Gemini Usage Rules

Credits are limited. Use Gemini only for agents 1, 3, 4, 6.

Never use Gemini for: Persona Agent, Critic Agent, UI logic, or database operations.

```
temperature:       0.3
maxOutputTokens:   1000
responseMimeType:  application/json
```

If Gemini fails: load fallback JSON from `classpath:sample-data/`, continue workflow, mark confidence low.

---

## Frontend Structure

```
frontend/lib/
├── main.dart
├── app/
│   ├── app.dart          # MeetWiseApp — Provider + MaterialApp
│   └── routes.dart       # Named routes: / /dashboard /trace /report
├── core/
│   └── responsive.dart   # Responsive.centered() for web layout
├── models/
│   ├── session_response.dart        # AgentRun, AgentTrace, FinalReport, SessionResponse
│   ├── meeting_request_model.dart   # POST payload + read-back model
│   ├── agent_trace_model.dart       # Pipeline view model (merges run + trace)
│   └── final_report_model.dart      # Parsed report + ConversationPhase, ObjectionResponse, DoAndDont
├── services/
│   └── api_service.dart  # HTTP — createMeeting, runDemo, getSession
├── screens/
│   ├── meeting_input_screen.dart    # Input form + agent pipeline preview
│   ├── agent_dashboard_screen.dart  # Per-agent run cards with confidence + output
│   ├── agent_trace_screen.dart      # Pipeline column + influence detail panel
│   └── final_report_screen.dart     # Parsed report sections
├── widgets/
│   └── confidence_badge.dart        # Reusable score display
└── theme/
    ├── app_theme.dart    # AppTheme.light — full ThemeData
    ├── app_colors.dart   # AppColors — palette + forConfidence() helpers
    └── app_spacing.dart  # AppSpacing — 4-pt grid, radii, EdgeInsets presets
```

---

## Frontend Coding Rules

### Navigation

Always use named routes with typed arguments. Never use `MaterialPageRoute` inline:

```dart
// Correct
Navigator.pushNamed(context, Routes.dashboard, arguments: session);

// Wrong — do not do this
Navigator.push(context, MaterialPageRoute(builder: (_) => Screen()));
```

### Colors

Never write confidence color logic inline. Use the helpers:

```dart
// Correct
AppColors.forConfidence(score)
AppColors.forConfidenceSurface(score)

// Wrong — do not repeat this pattern
score >= 0.8 ? Colors.green : score >= 0.5 ? Colors.orange : Colors.red
```

### Spacing

Never use raw numeric literals for layout. Use `AppSpacing`:

```dart
// Correct
padding: AppSpacing.cardPadding
const SizedBox(height: AppSpacing.md)

// Wrong
padding: const EdgeInsets.all(16)
const SizedBox(height: 16)
```

### Models

- `fromJson` must always use safe defaults (`?? ''`, `?? 0.0`, `?? []`) — never throw on missing keys.
- `toJson` on request models emits only backend-validated fields.
- Never call `jsonDecode` inside a widget — models parse nested JSON at construction time.
- Use `AgentTraceModel.fromSession(session)` to build the full trace list.
- Use `FinalReportModel.fromDto(dto)` to upgrade a raw `FinalReport` with parsed sub-fields.

### Widgets

- Wrap wide-screen page bodies with `Responsive.centered(context, child)`.
- Use `AppTheme.cardDecoration` for card containers.
- Use `AppTheme.codeDecoration` + `AppTheme.monoStyle` for JSON/raw output blocks.
- Use `AppTheme.brandSurface` or `AppColors.brandGradient` for hero/banner sections.

---

## Required UI Screens

| Screen | Route | Key Feature |
|---|---|---|
| Meeting Input | `/` | Form + agent pipeline chip preview |
| Agent Dashboard | `/dashboard` | Per-agent cards, confidence, execution time |
| Agent Trace View | `/trace` | **Most important** — directional influence arrows |
| Final Report | `/report` | Parsed sections: brief, flow, questions, objections, next steps |

### Agent Trace View — judging priority

The trace screen must show:
- Each agent as a selectable card with confidence bar
- Inbound influences (which agents fed data into this one)
- Outbound influences (which agents this one influenced)
- `influenceDescription` text for each link
- The key demo story: `CriticValidatorAgent` flags issues → `FinalSynthesisAgent` incorporates them

---

## Demo Mode

Must always work without Gemini:

- Use `POST /api/meetings/demo` — Apollo Hospitals example
- Full 6-agent pipeline executes
- Complete trace visualization available
- Works even when API quota is exhausted

---

## Database Tables

| Table | Purpose |
|---|---|
| `meeting_requests` | Input + session binding + status |
| `agent_runs` | Per-agent execution record (input, output, confidence, timing) |
| `agent_trace` | Directional influence links between agents |
| `final_reports` | Parsed final output from FinalSynthesisAgent |

No additional tables unless strictly necessary.

---

## Success Criteria

The project succeeds when judges can observe:

1. Six agents exist and run in sequence
2. Each agent reads and references prior agent outputs
3. Agent trace is visible with directional influence links
4. CriticValidator findings appear in FinalSynthesis output
5. Final meeting brief is complete and useful
6. Workflow survives Gemini failures (demo mode works)
7. Confidence scores reflect actual output quality

Every implementation decision should maximize these criteria.
