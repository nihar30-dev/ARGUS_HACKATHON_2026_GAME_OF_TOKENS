# Demo Script — Apollo Hospitals Scenario

## Setup (before judges arrive)

1. Run `POST /api/meetings/demo` once to warm the DB with the seeded session.
2. Open the Flutter app. Tap **Run Demo (Apollo Hospitals)**.
3. The pipeline completes in < 5 seconds (all fallback JSONs, no Gemini).

---

## What to Show Judges

### Screen 1 — Agent Dashboard
- Point out the **6 agent cards** running sequentially.
- Show the **influenced-by chips** under Strategy, Objections, Critic, Final — these prove interdependency.
- Show **confidence scores** per agent — Critic is always 1.0 (rule-based), others vary.
- Point out **Gemini AI vs Rule-based** badges.

### Screen 2 — Agent Trace View (MOST IMPORTANT)
- Click **Research** → show that it has **0 inbound** (it's first) but **2 outbound** arrows.
- Click **Objections** → show it has **3 inbound** (Research + Persona + Strategy all fed into it).
- Click **Critic** → show it received input from all 4 prior agents.
- Click **Synthesis** → show it received input from all 5 prior agents, including the Critic's warnings.
- Say: *"This is not a single LLM call. This is 6 agents collaborating. The Critic found a gap in the Strategy — that gap is visible in the trace and was fixed in the final brief."*

### Screen 3 — Final Report
- Show the **Conversation Flow timeline** — 5 phases, each informed by what the agents discovered.
- Show the **Objection Responses** — these came from the Objection agent and were validated by the Critic.
- Point to the **agent influence footer**: *"This brief was shaped by X influence connections."*

---

## Key Messages for Judges

| Hackathon Criterion | What to Point To |
|---|---|
| Agent Collaboration | 6 agents, 8 trace connections visible |
| Agent Orchestration | Sequential pipeline, each reads prior outputs |
| Agent Interdependency | `influencedBy` chips on every card |
| Traceability | Agent Trace View with directional influence arrows |
| Final Decision Quality | Critic improved the Final brief — shown in trace |

---

## Fallback if Gemini Quota Runs Out

The system **does not crash**. All 4 Gemini agents load from fallback JSONs. The demo works 100% without Gemini. If the API fails mid-demo, the response will have `usedGemini: false` with `confidence: 0.1` for affected agents — which actually makes for a great demo of the error-handling resilience.
