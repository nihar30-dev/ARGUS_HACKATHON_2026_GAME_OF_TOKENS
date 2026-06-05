# MeetWise Multi-Agent Meeting Preparation Assistant Skill

## Purpose

This skill enables Claude Code to build and maintain the MeetWise platform.

MeetWise is a Multi-Agent Decision Intelligence System that prepares users for important business meetings by orchestrating specialized AI agents.

The solution is being developed for a hackathon focused on:

* Agent Collaboration
* Agent Orchestration
* Agent Interdependency
* Traceability
* Final Decision Quality

The goal is NOT to generate a single AI response.

The goal is to demonstrate how multiple specialized agents collaborate, challenge assumptions, influence one another, and collectively produce a superior meeting preparation strategy.

---

# Technology Stack

Frontend:

* Flutter
* Material 3

Backend:

* Java 21
* Spring Boot 3

Database:

* PostgreSQL

LLM:

* Gemini 2.5 Flash

---

# Architecture Principles

Always follow:

1. Clean Architecture
2. SOLID Principles
3. Modular Agent Design
4. Traceability
5. Extensibility

Every component must be designed so future teams can add new agents without changing existing agents.

---

# Agent Architecture

MeetWise contains six agents.

## Organization Research Agent

Purpose:
Analyze target organization.

Input:

* Organization Name
* Meeting Objective
* Offering Description

Output:

* Organization Summary
* Business Priorities
* Pain Points
* Partnership Opportunities

---

## Stakeholder Persona Agent

Purpose:
Understand meeting participant.

Input:

* Stakeholder Role
* Organization Research Output

Output:

* Priorities
* Communication Style
* Decision Lens
* Talking Points

This agent is rule-based and does not require Gemini.

---

## Engagement Strategy Agent

Purpose:
Create meeting strategy.

Input:

* Research Output
* Persona Output

Output:

* Meeting Goal
* Positioning
* Value Proposition
* Success Criteria

Requires Gemini.

---

## Objection Prediction Agent

Purpose:
Challenge recommendations.

Input:

* Research Output
* Persona Output
* Strategy Output

Output:

* Objections
* Risks
* Counter Responses

Requires Gemini.

---

## Critic Validator Agent

Purpose:
Review outputs.

Responsibilities:

* Find contradictions
* Find unsupported assumptions
* Suggest improvements

This agent is rule-based.

---

## Final Synthesis Agent

Purpose:
Create final meeting preparation package.

Input:
All previous outputs.

Output:

* Executive Brief
* Conversation Flow
* Questions
* Objection Responses
* Next Steps

Requires Gemini.

---

# Agent Interdependency Rules

Agents must not operate independently.

Required flow:

Research Agent
→ Persona Agent
→ Strategy Agent
→ Objection Agent
→ Critic Agent
→ Final Agent

Each agent must explicitly reference outputs from previous agents.

Every agent output must include:

* influencedBy
* confidenceScore

Example:

{
"agent":"StrategyAgent",
"influencedBy":[
"ResearchAgent",
"PersonaAgent"
],
"confidenceScore":0.84
}

---

# Traceability Rules

Every agent execution must generate:

AgentTrace record.

AgentTrace contains:

* sourceAgent
* targetAgent
* inputSummary
* outputSummary
* influenceDescription
* timestamp

The UI must visualize this trace.

Traceability is a mandatory hackathon requirement.

---

# Gemini Usage Rules

Gemini credits are limited.

Optimize aggressively.

Use Gemini only for:

1. Organization Research Agent
2. Engagement Strategy Agent
3. Objection Prediction Agent
4. Final Synthesis Agent

Never use Gemini for:

* Persona Agent
* Critic Agent
* UI logic
* Database operations

Maximum output tokens:
1000

Temperature:
0.3

Response format:
JSON only

---

# Error Handling Rules

If Gemini fails:

1. Load fallback demo response.
2. Continue workflow.
3. Mark confidence as low.

System must never crash.

---

# UI Rules

Required Screens:

1. Meeting Input
2. Agent Execution Dashboard
3. Agent Trace View
4. Final Report

Most important screen:

Agent Trace View

The Trace View must clearly show:

* Agent Inputs
* Agent Outputs
* Agent Influence
* Agent Dependencies

---

# Database Rules

Required Tables:

meeting_requests

agent_runs

agent_trace

final_reports

No additional tables unless necessary.

---

# Demo Rules

Always support Demo Mode.

Demo Mode should:

* Use Apollo Hospitals example
* Execute full workflow
* Show trace visualization
* Work without Gemini

The demo must succeed even if API quota is exhausted.

---

# Coding Rules

When generating code:

* Generate production-quality code.
* Prefer simplicity over abstraction.
* Avoid premature optimization.
* Avoid unnecessary frameworks.
* Keep hackathon timelines in mind.

Always generate:

* DTOs
* Validation
* Exception Handling
* Logging

Never generate placeholder TODO code unless explicitly requested.

---

# Success Criteria

The project is successful when:

1. Multiple agents exist.
2. Agents influence each other.
3. Agent trace is visible.
4. Final recommendation is generated.
5. Workflow survives API failures.
6. Judges can clearly observe orchestration.

Optimize every implementation decision toward maximizing hackathon evaluation scores.