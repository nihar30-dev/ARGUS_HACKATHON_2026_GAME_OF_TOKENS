# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MeetWise is a hybrid multi-agent meeting preparation assistant for the ARGUS Hackathon 2026. Six specialized agents collaborate in sequence — each reading prior agents' outputs — to produce a meeting strategy. The hackathon judging criterion is **Agent Trace View**: visible proof that agents influenced one another.

---

## Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Spring Boot 3.2.5, Maven — package `com.argusoft.meetwise` |
| Frontend | Flutter (Dart), Material 3, `provider` for DI |
| Database | PostgreSQL — 4 tables: `meeting_requests`, `agent_runs`, `agent_trace`, `final_reports` |
| LLM | Gemini 2.5 Flash via REST (`gemini.api.url` in `application.properties`) |

---

## Commands

**Backend:**
```bash
cd backend
mvn spring-boot:run                        # start on :8080
mvn test
mvn clean package -DskipTests
```

**Frontend:**
```bash
cd frontend
flutter pub get
flutter run -d chrome                      # web (connects to localhost:8080)
flutter run                                # mobile/desktop
flutter analyze lib/                       # lint check
```

**Database:**
```bash
psql -U postgres -c "CREATE DATABASE meetwise;"
psql -U postgres -d meetwise -f database/01_schema.sql
psql -U postgres -d meetwise -f database/02_seed_demo.sql   # Apollo Hospitals demo data
```

**Quick demo (no Gemini needed):**
```bash
curl -X POST http://localhost:8080/api/meetings/demo
```

---

## Agent Architecture

Six agents run sequentially. Each is a Spring `@Component` implementing `Agent`, sorted by `getOrder()`.

| Order | Agent | Type | Reads From |
|---|---|---|---|
| 1 | `OrganizationResearchAgent` | Gemini | — |
| 2 | `StakeholderPersonaAgent` | Rule-based | Research |
| 3 | `EngagementStrategyAgent` | Gemini | Research + Persona |
| 4 | `ObjectionPredictionAgent` | Gemini | Research + Persona + Strategy |
| 5 | `CriticValidatorAgent` | Rule-based | All 4 above |
| 6 | `FinalSynthesisAgent` | Gemini | All 5 above |

**Adding a new agent:** Implement `Agent`, annotate `@Component`, set a unique `getOrder()` — the orchestrator auto-discovers it.

---

## Key Backend Rules

- Every agent output JSON must include `confidenceScore` and `influencedBy[]`.
- Every agent writes one `AgentTrace` row per source in `influencedBy[]` — this powers the Trace View.
- Gemini agents (1, 3, 4, 6) catch exceptions and fall back to `classpath:sample-data/*_fallback.json`.
- Rule-based agents (2, 5) never call Gemini.
- `DEMO_MODE=true` skips all Gemini calls without changing agent logic.
- Gemini config: `temperature=0.3`, `maxOutputTokens=1000`, `responseMimeType=application/json`.

---

## Environment Variables

| Variable | Default | Notes |
|---|---|---|
| `GEMINI_API_KEY` | (required for live) | Not needed when `DEMO_MODE=true` |
| `DB_URL` | `jdbc:postgresql://localhost:5432/meetwise` | |
| `DB_USERNAME` | `postgres` | |
| `DB_PASSWORD` | `postgres` | |
| `DEMO_MODE` | `false` | `true` = use fallback JSONs |

---

## API Endpoints

| Method | Path | Returns |
|---|---|---|
| `POST` | `/api/meetings` | `MeetingSessionResponseDTO` (full pipeline run) |
| `POST` | `/api/meetings/demo` | Same, using Apollo Hospitals fallback data |
| `GET` | `/api/meetings/{sessionId}` | Stored session |
| `GET` | `/api/meetings/{sessionId}/traces` | Trace records only |
| `GET` | `/api/meetings/{sessionId}/report` | Final report only |

---

## Frontend Architecture

### Folder structure

```
frontend/lib/
├── main.dart                        # runApp(MeetWiseApp())
├── app/
│   ├── app.dart                     # MeetWiseApp widget (Provider + MaterialApp)
│   └── routes.dart                  # Routes constants + onGenerateRoute
├── core/
│   └── responsive.dart              # Responsive.isMobile / contentMaxWidth / centered()
├── models/
│   ├── session_response.dart        # AgentRun, AgentTrace, FinalReport, SessionResponse
│   ├── meeting_request_model.dart   # POST payload + full entity read-back
│   ├── agent_trace_model.dart       # Pipeline view model (merges AgentRun + AgentTrace)
│   └── final_report_model.dart      # Parsed report + sub-models (ConversationPhase, etc.)
├── services/
│   └── api_service.dart             # HTTP calls to Spring backend
├── screens/
│   ├── meeting_input_screen.dart    # Route: /
│   ├── agent_dashboard_screen.dart  # Route: /dashboard  (arg: SessionResponse)
│   ├── agent_trace_screen.dart      # Route: /trace      (arg: SessionResponse)
│   └── final_report_screen.dart     # Route: /report     (arg: SessionResponse)
├── widgets/
│   └── confidence_badge.dart        # Reusable confidence % display
└── theme/
    ├── app_theme.dart               # AppTheme.light — full ThemeData
    ├── app_colors.dart              # AppColors — semantic palette + helpers
    └── app_spacing.dart             # AppSpacing — 4-pt scale, radii, EdgeInsets
```

### Navigation (named routes)

All navigation uses `Navigator.pushNamed` with typed arguments:

```dart
// Navigate to dashboard
Navigator.pushNamed(context, Routes.dashboard, arguments: session);

// Navigate to trace view
Navigator.pushNamed(context, Routes.trace, arguments: session);

// Navigate to final report
Navigator.pushNamed(context, Routes.report, arguments: session);
```

Adding a new screen: add a constant + case in `lib/app/routes.dart`, create the screen file in `lib/screens/`.

### Design system

**Colors** — use `AppColors` for semantic values; use `Theme.of(context).colorScheme` for Material roles:
```dart
AppColors.forConfidence(score)         // foreground color
AppColors.forConfidenceSurface(score)  // background tint
AppColors.brand                        // primary blue #2563EB
AppColors.accent                       // indigo #6366F1 (AI/Gemini badge)
```

**Spacing** — use `AppSpacing` constants instead of raw numbers:
```dart
AppSpacing.pagePadding      // EdgeInsets.all(24)
AppSpacing.cardPadding      // EdgeInsets.all(16)
AppSpacing.gapMd            // SizedBox(height: 16)
AppSpacing.roundedLg        // BorderRadius.circular(16)
```

**Theme presets** — use `AppTheme` decoration helpers:
```dart
AppTheme.cardDecoration     // white card with outline border
AppTheme.codeDecoration     // surfaceCode background for JSON blocks
AppTheme.monoStyle          // monospace TextStyle for raw output
```

**Responsive** — wrap page body content for web centering:
```dart
body: SingleChildScrollView(
  child: Responsive.centered(context, Column(...)),
)
```

### Model conventions

- `fromJson` always uses safe defaults (`?? ''`, `?? 0.0`, `?? []`) — never throws on missing keys.
- `toJson` on request models emits only the fields the backend validates.
- `AgentTraceModel.fromSession(session)` builds the full pipeline list in one call.
- `FinalReportModel.fromDto(dto)` upgrades the raw `FinalReport` with all JSON sub-fields parsed.
- Do **not** call `jsonDecode` inside widgets — let the model layer handle it.

### Confidence score colors

Never write the ternary inline. Always use:
```dart
AppColors.forConfidence(score)         // Colors.green / orange / red equivalents
AppColors.forConfidenceSurface(score)  // light background tint
AppColors.forConfidenceSubtle(score)   // subtle border/progress tint
```

---

## Highest Scoring Feature

The **Agent Trace View** (`agent_trace_screen.dart`) must show directional arrows from source → target agents with `influenceDescription` text. The story: `CriticValidatorAgent` finds issues → `FinalSynthesisAgent` incorporates them. This is the key demo moment for judges.
