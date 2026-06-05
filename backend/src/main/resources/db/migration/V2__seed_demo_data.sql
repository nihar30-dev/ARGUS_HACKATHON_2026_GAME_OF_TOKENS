-- MeetWise demo seed — Flyway V2
-- Apollo Hospitals partnership discussion scenario.
-- Used by POST /api/meetings/demo and pre-loads the Trace View for judges.

DO $$
DECLARE
    v_meeting UUID := '00000000-0000-0000-0000-000000000001';
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
) ON CONFLICT (id) DO NOTHING;

-- ── agent_runs ─────────────────────────────────────────────────
INSERT INTO agent_runs (meeting_request_id, agent_name, execution_order,
    input_payload, output_payload, confidence_score, influenced_by, used_gemini, execution_ms)
VALUES

(v_meeting, 'OrganizationResearchAgent', 1,
 '{"summary": "Apollo Hospitals | CEO | MEDplat digital health partnership"}',
 '{
    "agent": "OrganizationResearchAgent",
    "organizationSummary": "Apollo Hospitals is India''s largest integrated healthcare group with 73 hospitals, 10,000+ beds, and a publicly listed Apollo HealthCo digital unit. They are aggressively digitising clinical operations and expanding AI-assisted diagnostics.",
    "businessPriorities": ["Scale digital health via Apollo HealthCo", "Reduce operational cost through AI automation", "Expand telemedicine reach across tier-2/3 cities", "Achieve NABH and JCI accreditation across all units"],
    "painPoints": ["Clinical staff spend 35-40% of time on documentation", "Fragmented patient data across 73 hospitals", "High nurse attrition from administrative overload", "Limited telehealth penetration in non-metro markets"],
    "partnershipOpportunities": ["Co-develop AI diagnostics modules for Apollo HealthCo", "White-label MEDplat for Apollo Pharmacy digital kiosks", "Joint GTM in Southeast Asian expansion markets"],
    "confidenceScore": 0.91,
    "influencedBy": []
 }',
 0.910, '', TRUE, 2340),

(v_meeting, 'StakeholderPersonaAgent', 2,
 '{"summary": "Role: CEO | Organization research output"}',
 '{
    "agent": "StakeholderPersonaAgent",
    "stakeholderRole": "CEO",
    "priorities": ["Competitive differentiation in digital health", "Revenue growth through new business models", "Board-level narrative for Apollo HealthCo IPO", "Speed of execution — strategic impatience"],
    "communicationStyle": "strategic",
    "decisionLens": "strategic_value",
    "talkingPoints": ["Market opportunity size", "Competitive moat MEDplat creates", "Revenue share models", "Timeline to first patient impact"],
    "confidenceScore": 1.0,
    "influencedBy": ["OrganizationResearchAgent"]
 }',
 1.000, 'OrganizationResearchAgent', FALSE, 8),

(v_meeting, 'EngagementStrategyAgent', 3,
 '{"summary": "Research + CEO persona → meeting strategy"}',
 '{
    "agent": "EngagementStrategyAgent",
    "meetingGoal": "Secure CEO sponsorship for a joint MEDplat pilot across 5 Apollo hospitals within Q3",
    "positioning": "Position MEDplat as the digital infrastructure layer for Apollo HealthCo''s IPO story — not just a vendor but a co-growth partner",
    "valueProposition": "MEDplat adds a digital health revenue stream to Apollo''s 73-hospital network without requiring internal R&D investment.",
    "successCriteria": ["CEO agrees to introduce MEDplat to Apollo HealthCo leadership", "Pilot scope defined: 5 hospitals, 90 days", "Co-branding and revenue-share term sheet discussion initiated"],
    "openingApproach": "Open with the Apollo HealthCo IPO context — frame MEDplat as a strategic asset that strengthens the digital health narrative, not a cost item",
    "keyMessages": ["MEDplat is already live in 3 hospital chains — zero R&D risk for Apollo", "White-label model: Apollo brand, MEDplat infrastructure", "Revenue share from telemedicine and diagnostics — new income stream, not a cost"],
    "confidenceScore": 0.88,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent"]
 }',
 0.880, 'OrganizationResearchAgent,StakeholderPersonaAgent', TRUE, 3120),

(v_meeting, 'ObjectionPredictionAgent', 4,
 '{"summary": "Research + Persona + Strategy → objection prediction"}',
 '{
    "agent": "ObjectionPredictionAgent",
    "objections": [
      {"objection": "We are already building our own digital health platform in-house via Apollo HealthCo — why partner?", "likelihood": 0.88, "category": "competition", "counterResponse": "MEDplat accelerates Apollo HealthCo''s roadmap by 18-24 months. We become the infrastructure you build on top of, not a competitor. Three competing hospital chains tried to build in-house and came back to us within 2 years."},
      {"objection": "Our board is focused on the HealthCo IPO — this is not the right time for a new vendor relationship.", "likelihood": 0.82, "category": "timing", "counterResponse": "This is exactly the right time. A live MEDplat partnership strengthens the HealthCo IPO narrative with a proven revenue model and digital patient engagement metrics. We can be live in 5 hospitals before the IPO filing window."},
      {"objection": "Data privacy and patient consent for AI diagnostics is a regulatory minefield in India.", "likelihood": 0.75, "category": "technical", "counterResponse": "MEDplat is DPDPA-compliant and has cleared CDSCO scrutiny for AI diagnostics. We can share our compliance documentation and arrange a call with our legal counsel today."},
      {"objection": "The revenue share model will not pass our CFO''s scrutiny.", "likelihood": 0.65, "category": "price", "counterResponse": "We offer an alternative: fixed licensing fee with a performance bonus tied to patient volume milestones. CFO controls the cost ceiling while Apollo captures upside."}
    ],
    "topRisks": ["Apollo HealthCo team may see MEDplat as a threat to their internal build roadmap", "CEO may delegate to a committee, extending the decision timeline past the IPO window"],
    "confidenceScore": 0.84,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent"]
 }',
 0.840, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent', TRUE, 2890),

(v_meeting, 'CriticValidatorAgent', 5,
 '{"summary": "Validating all 4 prior agent outputs"}',
 '{
    "agent": "CriticValidatorAgent",
    "validationPassed": true,
    "issues": [
      {"agentName": "EngagementStrategyAgent", "severity": "warning", "issue": "IPO timing assumption is unverified — strategy relies on Apollo HealthCo IPO being imminent, but no confirmation in research output"},
      {"agentName": "ObjectionPredictionAgent", "severity": "warning", "issue": "Highest-likelihood objection (in-house build, 0.88) has no corresponding key message in strategy — gap in objection coverage"}
    ],
    "improvements": [
      "Verify Apollo HealthCo IPO timeline before leading with that narrative",
      "Add a direct in-house build counter-narrative to the strategy key messages",
      "Include a specific reference customer name in the demonstration to build credibility"
    ],
    "overallConfidenceScore": 0.876,
    "confidenceScore": 1.0,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent", "ObjectionPredictionAgent"]
 }',
 1.000, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent,ObjectionPredictionAgent', FALSE, 11),

(v_meeting, 'FinalSynthesisAgent', 6,
 '{"summary": "All 5 prior agents + critic improvements → final brief"}',
 '{
    "agent": "FinalSynthesisAgent",
    "executiveBrief": "Apollo''s CEO is a strategic, IPO-oriented decision-maker looking for competitive differentiation and new revenue streams for Apollo HealthCo. The optimal approach is to position MEDplat as the digital infrastructure that accelerates the HealthCo growth story — not a vendor cost. The in-house build objection (likelihood 0.88) must be pre-empted by leading with build-vs-partner economics and a named reference customer before the CEO raises it.",
    "conversationFlow": [
      {"phase": "Opening", "duration": "5 min", "approach": "Frame MEDplat as an Apollo HealthCo growth accelerator, not a vendor pitch. Reference one named comparable hospital group as proof. Do NOT open with product features."},
      {"phase": "Discovery", "duration": "10 min", "approach": "Ask about the Apollo HealthCo IPO roadmap and digital health KPIs. Confirm the internal build team status and their 18-month delivery estimate. Quantify the build cost."},
      {"phase": "Demonstration", "duration": "15 min", "approach": "Show the white-label model with Apollo branding live. Present the revenue model with 3-year projections. Reference a comparable hospital''s patient volume uplift."},
      {"phase": "Objection Handling", "duration": "10 min", "approach": "Address in-house build with build-vs-partner economics. Show DPDPA compliance certification. Present two pricing models (rev share and fixed+performance)."},
      {"phase": "Close", "duration": "5 min", "approach": "Propose a CEO-sponsored 90-day pilot in 5 hospitals. Ask for an introduction to the Apollo HealthCo leadership team. Define 3 IPO-ready success metrics together."}
    ],
    "topQuestions": [
      "What is the Apollo HealthCo digital health roadmap for the next 18 months, and what is the internal build team''s current scope?",
      "Which 5 hospitals would you consider for a 90-day pilot that generates IPO-ready patient engagement metrics?",
      "What does a successful partnership look like in your board narrative — revenue share, white-label, or co-brand?"
    ],
    "objectionResponses": [
      {"objection": "We are building in-house via Apollo HealthCo", "response": "MEDplat accelerates your roadmap by 18-24 months. We become the infrastructure you build on, not a competitor. We can share a build-vs-partner cost analysis."},
      {"objection": "Not the right time — IPO focus", "response": "This strengthens the IPO narrative. Live in 5 hospitals before the filing window with proven revenue model and patient engagement metrics."},
      {"objection": "Data privacy regulatory risk", "response": "DPDPA-compliant, CDSCO-cleared. Compliance documentation and legal counsel call available today."},
      {"objection": "CFO won''t approve revenue share", "response": "Alternative: fixed licensing + performance bonus tied to patient volume. CFO controls cost ceiling, Apollo captures upside."}
    ],
    "nextSteps": [
      "Share build-vs-partner cost analysis and named reference customer case study within 24 hours",
      "CEO introduces MEDplat to Apollo HealthCo leadership team within 1 week",
      "Define 5 pilot hospitals and 3 IPO-ready success metrics in follow-up session"
    ],
    "criticImprovementsApplied": [
      "Added build-vs-partner economics to discovery phase to pre-empt the highest-likelihood objection",
      "Added named reference customer requirement to the demonstration phase",
      "Framed the opening around IPO narrative with a caveat to verify timeline before leading with it"
    ],
    "overallConfidenceScore": 0.90,
    "confidenceScore": 0.90,
    "influencedBy": ["OrganizationResearchAgent", "StakeholderPersonaAgent", "EngagementStrategyAgent", "ObjectionPredictionAgent", "CriticValidatorAgent"]
 }',
 0.900, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent,ObjectionPredictionAgent,CriticValidatorAgent', TRUE, 3780)

ON CONFLICT DO NOTHING;

-- ── agent_trace ────────────────────────────────────────────────
INSERT INTO agent_trace (meeting_request_id, source_agent, target_agent,
    input_summary, output_summary, influence_description)
VALUES
(v_meeting, 'OrganizationResearchAgent', 'StakeholderPersonaAgent',
 'Apollo: digital health focus, CEO-led transformation',
 'CEO persona: strategic communicator, IPO-oriented decision lens',
 'Research identified Apollo HealthCo IPO intent and CEO''s digital transformation mandate, which set the strategic decision lens for the CEO persona'),

(v_meeting, 'OrganizationResearchAgent', 'EngagementStrategyAgent',
 'Apollo pain points: fragmented data, digital health monetisation gap',
 'Strategy: position MEDplat as HealthCo IPO accelerator, not vendor cost',
 'Research finding of Apollo HealthCo as a revenue-growth vehicle directly shaped the IPO-centred positioning strategy'),

(v_meeting, 'StakeholderPersonaAgent', 'EngagementStrategyAgent',
 'CEO: strategic communicator, competitive differentiation priority',
 'Opening: IPO narrative frame; key message: new revenue stream not a cost',
 'CEO''s strategic communication style and focus on board narrative determined the IPO-framed opening approach and revenue-share positioning'),

(v_meeting, 'OrganizationResearchAgent', 'ObjectionPredictionAgent',
 'Apollo: has internal Apollo HealthCo build team',
 'Top objection: in-house build (likelihood 0.88)',
 'Research finding of the Apollo HealthCo internal development unit directly generated the highest-likelihood objection prediction'),

(v_meeting, 'StakeholderPersonaAgent', 'ObjectionPredictionAgent',
 'CEO: strategic impatience, IPO timeline sensitivity',
 'Objection: board IPO focus makes this wrong time (likelihood 0.82)',
 'CEO persona''s IPO timeline sensitivity generated the timing objection as the second-highest-likelihood prediction'),

(v_meeting, 'EngagementStrategyAgent', 'ObjectionPredictionAgent',
 'Strategy: revenue-share model, white-label positioning',
 'Objection: CFO revenue-share scrutiny (likelihood 0.65)',
 'The revenue-share strategy directly triggered the CFO scrutiny objection prediction'),

(v_meeting, 'ObjectionPredictionAgent', 'CriticValidatorAgent',
 'Top objection (0.88): in-house build not in strategy key messages',
 'Warning: strategy gap — highest-likelihood objection uncovered',
 'Critic detected that the highest-likelihood objection had no corresponding key message in the strategy, flagging it as a warning that required remediation'),

(v_meeting, 'CriticValidatorAgent', 'FinalSynthesisAgent',
 'Warnings: IPO assumption unverified; in-house objection uncovered in strategy',
 'Synthesis added build-vs-partner economics and reference customer to directly address both critic warnings',
 'Critic warnings directly caused the Final Synthesis to add build-vs-partner cost analysis to discovery phase and a reference customer to the demonstration phase')

ON CONFLICT DO NOTHING;

-- ── final_reports ──────────────────────────────────────────────
INSERT INTO final_reports (meeting_request_id, report_payload, overall_confidence)
SELECT
    v_meeting,
    output_payload,
    0.900
FROM agent_runs
WHERE meeting_request_id = v_meeting
  AND agent_name = 'FinalSynthesisAgent'
ON CONFLICT (meeting_request_id) DO NOTHING;

END $$;
