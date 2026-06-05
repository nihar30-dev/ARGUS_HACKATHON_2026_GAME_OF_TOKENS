-- MeetWise — demo insert
-- Meeting: Apollo Hospitals Partnership Discussion
-- Organization: Apollo Hospitals
-- Stakeholder Role: CEO
-- Objective: Discuss MEDplat digital health platform partnership
-- Offering: MEDplat digital health platform
--
-- Run after schema.sql:
--   psql -U postgres -d meetwise -f database/sample_insert.sql

DO $$
DECLARE
    v_meeting UUID := uuid_generate_v4();
BEGIN

-- ── meeting_requests ───────────────────────────────────────────
INSERT INTO meeting_requests (id, organization_name, stakeholder_role,
    meeting_objective, offering_description, status)
VALUES (
    v_meeting,
    'Apollo Hospitals',
    'CEO',
    'Discuss MEDplat digital health platform partnership',
    'MEDplat is a digital health platform that connects patients, doctors, and hospitals through AI-powered diagnostics, telemedicine, and clinical workflow automation. It integrates with existing HIS/EMR systems via HL7 FHIR APIs.',
    'COMPLETED'
);

-- ── agent_runs ─────────────────────────────────────────────────
INSERT INTO agent_runs (meeting_request_id, agent_name, execution_order,
    input_payload, output_payload, confidence_score, influenced_by, used_gemini, execution_ms)
VALUES

(v_meeting, 'OrganizationResearchAgent', 1,
 '{"summary": "Apollo Hospitals | CEO | MEDplat partnership"}',
 '{
    "agent": "OrganizationResearchAgent",
    "organizationSummary": "Apollo Hospitals is India largest integrated healthcare group with 73 hospitals and a publicly listed Apollo HealthCo digital unit pursuing aggressive digital health expansion.",
    "businessPriorities": ["Scale Apollo HealthCo digital revenue", "Reduce clinical staff administrative burden", "Expand telemedicine in tier-2/3 cities", "NABH and JCI compliance"],
    "painPoints": ["35-40% of clinical staff time spent on documentation", "Fragmented patient data across 73 hospitals", "Limited telehealth monetisation model", "High nurse attrition from administrative overload"],
    "partnershipOpportunities": ["Co-develop AI diagnostics for Apollo HealthCo", "White-label MEDplat under Apollo brand", "Joint Southeast Asia market entry"],
    "confidenceScore": 0.91,
    "influencedBy": []
 }',
 0.910, '', TRUE, 2400),

(v_meeting, 'StakeholderPersonaAgent', 2,
 '{"summary": "Role: CEO | Research output"}',
 '{
    "agent": "StakeholderPersonaAgent",
    "stakeholderRole": "CEO",
    "priorities": ["Competitive differentiation in digital health", "New revenue streams for Apollo HealthCo", "Board-level growth narrative", "Speed of execution"],
    "communicationStyle": "strategic",
    "decisionLens": "strategic_value",
    "talkingPoints": ["Market opportunity size", "Revenue model", "Competitive moat", "Time to first impact"],
    "confidenceScore": 1.0,
    "influencedBy": ["OrganizationResearchAgent"]
 }',
 1.000, 'OrganizationResearchAgent', FALSE, 9),

(v_meeting, 'EngagementStrategyAgent', 3,
 '{"summary": "Research + CEO persona"}',
 '{
    "agent": "EngagementStrategyAgent",
    "meetingGoal": "Secure CEO sponsorship for a 5-hospital MEDplat pilot in Q3",
    "positioning": "MEDplat as Apollo HealthCo growth infrastructure, not a vendor cost",
    "valueProposition": "MEDplat adds a digital health revenue stream without requiring Apollo to invest in R&D.",
    "successCriteria": ["CEO introduces MEDplat to HealthCo leadership", "5-hospital pilot scope agreed", "Revenue-share term sheet initiated"],
    "openingApproach": "Lead with the HealthCo revenue narrative and a named reference hospital",
    "keyMessages": ["Already live in 3 comparable hospital chains — zero R&D risk", "White-label: Apollo brand, MEDplat infrastructure", "Revenue share — new income stream, not a cost"],
    "confidenceScore": 0.88,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent"]
 }',
 0.880, 'OrganizationResearchAgent,StakeholderPersonaAgent', TRUE, 3200),

(v_meeting, 'ObjectionPredictionAgent', 4,
 '{"summary": "Research + Persona + Strategy"}',
 '{
    "agent": "ObjectionPredictionAgent",
    "objections": [
      {"objection": "We are building our own platform in-house via Apollo HealthCo.", "likelihood": 0.88, "category": "competition", "counterResponse": "MEDplat accelerates your roadmap by 18-24 months. We become the infrastructure you build on."},
      {"objection": "This is not the right time — the board is focused on the HealthCo IPO.", "likelihood": 0.82, "category": "timing", "counterResponse": "This strengthens the IPO story. Live in 5 hospitals before the filing window."},
      {"objection": "Data privacy and AI diagnostics face regulatory risk in India.", "likelihood": 0.75, "category": "technical", "counterResponse": "DPDPA-compliant, CDSCO-cleared. Compliance docs available today."},
      {"objection": "The revenue share model will not pass CFO scrutiny.", "likelihood": 0.65, "category": "price", "counterResponse": "Alternative: fixed fee plus performance bonus tied to patient volume milestones."}
    ],
    "topRisks": ["Apollo HealthCo internal team sees MEDplat as a threat", "CEO delegates to committee, extending timeline past IPO window"],
    "confidenceScore": 0.84,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"]
 }',
 0.840, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent', TRUE, 2900),

(v_meeting, 'CriticValidatorAgent', 5,
 '{"summary": "Validating all 4 prior agent outputs"}',
 '{
    "agent": "CriticValidatorAgent",
    "validationPassed": true,
    "issues": [
      {"agentName": "EngagementStrategyAgent", "severity": "warning", "issue": "Highest-likelihood objection (in-house build, 0.88) is not addressed in strategy key messages — gap in objection pre-emption"}
    ],
    "improvements": [
      "Add build-vs-partner economics counter to strategy key messages",
      "Include a named reference customer in the demonstration phase",
      "Verify HealthCo IPO timeline before leading with IPO narrative"
    ],
    "overallConfidenceScore": 0.878,
    "confidenceScore": 1.0,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent", "ObjectionPredictionAgent"]
 }',
 1.000, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent,ObjectionPredictionAgent', FALSE, 10),

(v_meeting, 'FinalSynthesisAgent', 6,
 '{"summary": "All 5 agents + critic improvements"}',
 '{
    "agent": "FinalSynthesisAgent",
    "executiveBrief": "Apollo CEO is an IPO-focused strategic decision-maker. Frame MEDplat as the digital infrastructure that accelerates the HealthCo growth story. Pre-empt the in-house build objection with build-vs-partner economics and a named reference customer before the CEO raises it.",
    "conversationFlow": [
      {"phase": "Opening", "duration": "5 min", "approach": "Frame MEDplat as a HealthCo revenue accelerator. Lead with a named reference hospital. Do not open with product features."},
      {"phase": "Discovery", "duration": "10 min", "approach": "Ask about HealthCo IPO KPIs and internal build team roadmap. Quantify their build cost."},
      {"phase": "Demonstration", "duration": "15 min", "approach": "Show white-label model with Apollo branding. Present 3-year revenue projections and reference patient volume uplift."},
      {"phase": "Objection Handling", "duration": "10 min", "approach": "Address in-house build with economics. Show DPDPA compliance. Present two pricing models."},
      {"phase": "Close", "duration": "5 min", "approach": "Propose CEO-sponsored 90-day pilot in 5 hospitals. Ask for HealthCo leadership introduction."}
    ],
    "topQuestions": [
      "What is the Apollo HealthCo digital roadmap and internal build team scope for the next 18 months?",
      "Which 5 hospitals would you consider for a 90-day pilot with IPO-ready patient engagement metrics?",
      "What does a successful partnership look like in your board narrative?"
    ],
    "objectionResponses": [
      {"objection": "Building in-house via Apollo HealthCo", "response": "MEDplat accelerates your roadmap by 18-24 months. We have the build-vs-partner cost analysis ready."},
      {"objection": "Not the right time — IPO focus", "response": "This strengthens the IPO narrative with a live revenue model in 5 hospitals before the filing window."},
      {"objection": "Data privacy regulatory risk", "response": "DPDPA-compliant, CDSCO-cleared. Full documentation available today."},
      {"objection": "CFO revenue share scrutiny", "response": "Fixed fee plus performance bonus tied to patient volume — CFO controls cost ceiling."}
    ],
    "nextSteps": [
      "Share build-vs-partner cost analysis and named reference case study within 24 hours",
      "CEO introduces MEDplat to Apollo HealthCo leadership within 1 week",
      "Define pilot hospitals and IPO-ready success metrics in follow-up session"
    ],
    "criticImprovementsApplied": [
      "Added build-vs-partner economics to discovery phase to pre-empt the top objection",
      "Added named reference customer requirement to the demonstration phase"
    ],
    "overallConfidenceScore": 0.90,
    "confidenceScore": 0.90,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent", "ObjectionPredictionAgent", "CriticValidatorAgent"]
 }',
 0.900, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent,ObjectionPredictionAgent,CriticValidatorAgent', TRUE, 3800);

-- ── agent_trace ────────────────────────────────────────────────
INSERT INTO agent_trace (meeting_request_id, source_agent, target_agent,
    input_summary, output_summary, influence_description)
VALUES
(v_meeting, 'OrganizationResearchAgent', 'StakeholderPersonaAgent',
 'Apollo HealthCo IPO intent identified', 'CEO: IPO-oriented strategic decision lens',
 'Research identified Apollo HealthCo IPO intent, setting the strategic lens for the CEO persona'),

(v_meeting, 'OrganizationResearchAgent', 'EngagementStrategyAgent',
 'Apollo pain points: fragmented data, digital monetisation gap', 'Strategy: HealthCo revenue accelerator positioning',
 'Research finding of Apollo HealthCo revenue opportunity shaped the IPO-centred positioning'),

(v_meeting, 'StakeholderPersonaAgent', 'EngagementStrategyAgent',
 'CEO: strategic, IPO board narrative priority', 'Opening: HealthCo revenue narrative; key message: new income stream',
 'CEO strategic style and board narrative focus determined the revenue-first opening approach'),

(v_meeting, 'OrganizationResearchAgent', 'ObjectionPredictionAgent',
 'Apollo has internal Apollo HealthCo build team', 'Top objection: in-house build (0.88)',
 'Internal build team finding directly triggered the highest-likelihood objection'),

(v_meeting, 'StakeholderPersonaAgent', 'ObjectionPredictionAgent',
 'CEO: IPO timeline sensitivity', 'Objection: wrong time for new vendor (0.82)',
 'CEO IPO sensitivity generated the timing objection as second-highest likelihood'),

(v_meeting, 'EngagementStrategyAgent', 'ObjectionPredictionAgent',
 'Strategy: revenue-share model', 'Objection: CFO scrutiny (0.65)',
 'Revenue-share strategy triggered the CFO scrutiny objection prediction'),

(v_meeting, 'ObjectionPredictionAgent', 'CriticValidatorAgent',
 'Top objection (0.88) not covered in strategy', 'Warning: strategy gap identified',
 'Critic detected the highest-likelihood objection had no key message counter in strategy'),

(v_meeting, 'CriticValidatorAgent', 'FinalSynthesisAgent',
 'Warnings: in-house objection uncovered; IPO assumption unverified',
 'Final synthesis added build-vs-partner economics and reference customer',
 'Critic warnings directly caused Final Synthesis to add objection pre-emption and reference customer to the meeting flow');

-- ── final_reports ──────────────────────────────────────────────
INSERT INTO final_reports (meeting_request_id, report_payload, overall_confidence)
SELECT meeting_request_id, output_payload, 0.900
FROM   agent_runs
WHERE  meeting_request_id = v_meeting
  AND  agent_name = 'FinalSynthesisAgent';

RAISE NOTICE 'Demo meeting inserted: %', v_meeting;
END $$;
