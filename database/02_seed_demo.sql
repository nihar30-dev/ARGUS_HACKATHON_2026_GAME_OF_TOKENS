-- Apollo Hospitals demo seed data
-- Inserts a complete pre-run session so judges can see the trace view
-- without executing the live pipeline.

DO $$
DECLARE
    v_session   UUID := '00000000-0000-0000-0000-000000000001';
    v_meeting   UUID := '00000000-0000-0000-0000-000000000002';
BEGIN

INSERT INTO meeting_requests (id, session_id, organization_name, meeting_objective,
    offering_description, stakeholder_role, status)
VALUES (v_meeting, v_session,
    'Apollo Hospitals',
    'Pitch our AI-powered clinical workflow automation platform',
    'A SaaS platform that automates clinical documentation, reduces nurse workload by 40%, and integrates with existing HIS/EMR systems via HL7 FHIR APIs.',
    'CTO',
    'COMPLETED')
ON CONFLICT DO NOTHING;

INSERT INTO agent_runs (session_id, agent_name, execution_order_index, output_json,
    confidence_score, influenced_by, used_gemini, execution_ms)
VALUES
(v_session, 'OrganizationResearchAgent', 1,
    '{"agent":"OrganizationResearchAgent","organizationSummary":"Apollo Hospitals is India''s largest integrated healthcare organization with 73 hospitals and 10,000+ beds. A publicly listed company (NSE: APOLLOHOSP) focused on digital health transformation and international patient care.","businessPriorities":["Digitizing clinical workflows across all hospital branches","Reducing operational costs amid rising staff shortages","Expanding telehealth and AI-assisted diagnostics","NABH and JCI accreditation compliance"],"painPoints":["Clinical staff spending 35-40% of time on documentation","Inconsistent patient data across HIS systems","High nurse attrition due to administrative burden","HL7 integration complexity across legacy systems"],"partnershipOpportunities":["Pilot at 3 flagship hospitals before chain-wide rollout","Integration with Apollo''s proprietary HIS (Astreya)","Co-develop AI modules for Apollo HealthCo digital unit"],"confidenceScore":0.91,"influencedBy":[]}',
    0.91, '', true, 2340),
(v_session, 'StakeholderPersonaAgent', 2,
    '{"agent":"StakeholderPersonaAgent","priorities":["Technical scalability across 73 hospitals","HL7 FHIR and existing HIS integration","Cybersecurity and patient data compliance","Vendor support SLA and implementation timeline"],"communicationStyle":"technical","decisionLens":"technical_feasibility","talkingPoints":["API architecture and FHIR compliance","Integration with Astreya HIS","Data sovereignty and on-premise deployment options","Pilot success metrics and rollout plan"],"confidenceScore":1.0,"influencedBy":["OrganizationResearchAgent"]}',
    1.0, 'OrganizationResearchAgent', false, 12),
(v_session, 'EngagementStrategyAgent', 3,
    '{"agent":"EngagementStrategyAgent","meetingGoal":"Secure a 3-hospital pilot agreement within 30 days","positioning":"Position as the only platform with native HL7 FHIR support AND pre-built Apollo Astreya connector","valueProposition":"Cut clinical documentation time by 40% in 90 days — measured and guaranteed by contractual SLA","successCriteria":["CTO agrees to technical deep-dive session","Pilot scope defined: 3 hospitals, 90-day timeline","IT team introductions scheduled"],"openingApproach":"Lead with the Astreya integration story — acknowledge the pain of custom HIS connectors upfront","keyMessages":["Pre-built Astreya connector — zero custom dev required","40% documentation time reduction proven at 2 comparable hospital chains","On-premise and hybrid deployment — full data sovereignty"],"confidenceScore":0.88,"influencedBy":["OrganizationResearchAgent","StakeholderPersonaAgent"]}',
    0.88, 'OrganizationResearchAgent,StakeholderPersonaAgent', true, 3120),
(v_session, 'ObjectionPredictionAgent', 4,
    '{"agent":"ObjectionPredictionAgent","objections":[{"objection":"We already have an in-house team building automation on top of Astreya — why buy external?","likelihood":0.92,"category":"competition","counterResponse":"Our connector took 18 months to build with a 6-person team. We can deploy it in your environment in 2 weeks. Your team''s time is better spent on clinical innovation, not HIS plumbing."},{"objection":"Patient data cannot leave our on-premise environment — cloud SaaS is non-starter.","likelihood":0.87,"category":"technical","counterResponse":"We support fully air-gapped on-premise deployment. Three of our existing clients operate in the same compliance posture. We can share our security architecture doc today."},{"objection":"We had a failed automation pilot with Vendor X 18 months ago — board is skeptical.","likelihood":0.75,"category":"trust","counterResponse":"We''ve specifically analysed those failure patterns. Our pilot structure is designed to produce measurable results in 30 days, not 6 months. We take on contractual risk through an outcome-based pricing model."},{"objection":"Budget cycle ends in Q3 — procurement takes 4 months minimum.","likelihood":0.70,"category":"timing","counterResponse":"We offer a zero-cost 30-day proof-of-concept that does not require procurement. Once results are proven, formal procurement runs in parallel with the extended pilot."}],"topRisks":["Internal build team resistance to external vendor","Astreya API limitations not yet scoped"],"confidenceScore":0.84,"influencedBy":["OrganizationResearchAgent","StakeholderPersonaAgent","EngagementStrategyAgent"]}',
    0.84, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent', true, 2890),
(v_session, 'CriticValidatorAgent', 5,
    '{"agent":"CriticValidatorAgent","validationPassed":true,"issues":[{"agentName":"ObjectionPredictionAgent","issue":"Objection about in-house team (likelihood 0.92) is not addressed in the strategy''s key messages — add a direct competitive differentiation point","severity":"warning"}],"improvements":["Add a direct counter to the in-house build argument in the opening approach","Include a reference customer in healthcare with similar Astreya integration","Quantify the 18-month/6-person build cost in the value proposition"],"overallConfidenceScore":0.87,"confidenceScore":1.0,"influencedBy":["OrganizationResearchAgent","StakeholderPersonaAgent","EngagementStrategyAgent","ObjectionPredictionAgent"]}',
    1.0, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent,ObjectionPredictionAgent', false, 8),
(v_session, 'FinalSynthesisAgent', 6,
    '{"agent":"FinalSynthesisAgent","executiveBrief":"Apollo''s CTO is a technically rigorous decision-maker focused on integration feasibility and data sovereignty. The highest-probability path to a pilot is leading with the pre-built Astreya connector and an outcome-based, zero-cost 30-day PoC that bypasses procurement delays.","conversationFlow":[{"phase":"Opening","duration":"5 min","approach":"Acknowledge the Astreya integration challenge directly. Show the connector live."},{"phase":"Discovery","duration":"10 min","approach":"Confirm current documentation time burden and the in-house build status. Quantify their team''s cost."},{"phase":"Demonstration","duration":"15 min","approach":"Live demo on a test Astreya instance. Show the 40% reduction metric from a comparable hospital."},{"phase":"Objection Handling","duration":"10 min","approach":"Address the in-house build objection with build cost analysis. Show the on-premise security architecture."},{"phase":"Close","duration":"5 min","approach":"Propose zero-cost 30-day PoC at one hospital. Define 3 measurable success criteria together."}],"topQuestions":["What is the current status of your in-house automation roadmap on Astreya?","Which 3 hospitals would you consider for a controlled pilot?","What does your data sovereignty requirement look like — on-premise, private cloud, or hybrid?"],"objectionResponses":[{"objection":"We already have an in-house build team","response":"Our connector took 18 months and a 6-person team. We deploy in 2 weeks. We can show build cost analysis."},{"objection":"Patient data cannot leave on-premise","response":"We support fully air-gapped deployment. We can share our security architecture today."},{"objection":"Failed pilot with Vendor X","response":"30-day PoC with contractual outcome SLAs — no procurement required to start."},{"objection":"Budget timing","response":"Zero-cost PoC starts immediately. Procurement runs parallel to extended pilot."}],"nextSteps":["Share Astreya connector technical specification document","Schedule 1-hour technical deep-dive with CTO and IT team","Define PoC success criteria and hospital selection together"],"criticImprovementsApplied":["Added direct in-house build cost counter in discovery phase","Added reference customer mention to demonstration phase","Included build cost analysis as a specific objection handling artifact"],"overallConfidenceScore":0.91,"confidenceScore":0.91,"influencedBy":["OrganizationResearchAgent","StakeholderPersonaAgent","EngagementStrategyAgent","ObjectionPredictionAgent","CriticValidatorAgent"]}',
    0.91, 'OrganizationResearchAgent,StakeholderPersonaAgent,EngagementStrategyAgent,ObjectionPredictionAgent,CriticValidatorAgent', true, 3780);

INSERT INTO agent_trace (session_id, source_agent, target_agent, input_summary, output_summary, influence_description)
VALUES
(v_session, 'OrganizationResearchAgent', 'StakeholderPersonaAgent',
    'Apollo Hospitals org analysis',
    'CTO technical persona with HL7/FHIR focus',
    'Research identified Astreya HIS and digital transformation priority, which shaped the CTO persona toward technical feasibility as the primary decision lens'),
(v_session, 'OrganizationResearchAgent', 'EngagementStrategyAgent',
    'Apollo pain points: documentation burden, HIS fragmentation',
    'Strategy: lead with Astreya connector + 40% doc reduction guarantee',
    'Pain points (documentation burden, HIS integration complexity) directly determined the positioning and the pre-built connector as the opening hook'),
(v_session, 'StakeholderPersonaAgent', 'EngagementStrategyAgent',
    'CTO: technical communicator, data sovereignty concern',
    'Strategy: open with Astreya integration story, on-premise deployment',
    'CTO''s technical communication style and data sovereignty concern shaped the opening approach and the on-premise deployment key message'),
(v_session, 'OrganizationResearchAgent', 'ObjectionPredictionAgent',
    'Apollo: has in-house HIS team, previous failed pilot',
    'Top objection: in-house build team (likelihood 0.92)',
    'Research finding of an existing in-house automation team triggered the highest-likelihood objection prediction'),
(v_session, 'StakeholderPersonaAgent', 'ObjectionPredictionAgent',
    'CTO: compliance-focused, skeptical of vendor promises',
    'Objection: data sovereignty non-starter for cloud SaaS',
    'CTO persona''s data sovereignty concern directly generated the on-premise objection with 0.87 likelihood'),
(v_session, 'EngagementStrategyAgent', 'ObjectionPredictionAgent',
    'Strategy: outcome-based PoC, bypass procurement',
    'Objection: budget timing concern, 4-month procurement',
    'The PoC bypass strategy triggered the objection prediction about budget timing and procurement cycles'),
(v_session, 'ObjectionPredictionAgent', 'CriticValidatorAgent',
    'Top objection: in-house build team not in strategy key messages',
    'Warning: strategy gap identified',
    'Critic identified that the highest-likelihood objection (0.92) had no corresponding key message in the strategy — flagged as warning'),
(v_session, 'CriticValidatorAgent', 'FinalSynthesisAgent',
    'Warning: in-house build objection not addressed; 3 improvement suggestions',
    'Final synthesis added build cost counter and reference customer',
    'Critic''s warning directly caused Final agent to add the in-house build cost analysis to the discovery phase and the reference customer to the demo phase');

INSERT INTO final_reports (session_id, meeting_request_id, executive_brief,
    conversation_flow_json, questions_json, objection_responses_json, next_steps_json, overall_confidence)
VALUES (v_session, v_meeting,
    'Apollo''s CTO is a technically rigorous decision-maker focused on integration feasibility and data sovereignty. The highest-probability path to a pilot is leading with the pre-built Astreya connector and an outcome-based, zero-cost 30-day PoC that bypasses procurement delays.',
    '[{"phase":"Opening","duration":"5 min","approach":"Acknowledge the Astreya integration challenge directly. Show the connector live."},{"phase":"Discovery","duration":"10 min","approach":"Confirm current documentation time burden and the in-house build status. Quantify their team cost."},{"phase":"Demonstration","duration":"15 min","approach":"Live demo on a test Astreya instance. Show the 40% reduction metric from a comparable hospital."},{"phase":"Objection Handling","duration":"10 min","approach":"Address the in-house build objection with build cost analysis. Show the on-premise security architecture."},{"phase":"Close","duration":"5 min","approach":"Propose zero-cost 30-day PoC at one hospital. Define 3 measurable success criteria together."}]',
    '["What is the current status of your in-house automation roadmap on Astreya?","Which 3 hospitals would you consider for a controlled pilot?","What does your data sovereignty requirement look like?"]',
    '[{"objection":"We already have an in-house build team","response":"Our connector took 18 months and a 6-person team. We deploy in 2 weeks."},{"objection":"Patient data cannot leave on-premise","response":"We support fully air-gapped deployment. Security architecture available today."},{"objection":"Failed pilot with Vendor X","response":"30-day PoC with contractual outcome SLAs. No procurement required."},{"objection":"Budget timing","response":"Zero-cost PoC starts immediately. Procurement runs parallel."}]',
    '["Share Astreya connector technical specification document","Schedule 1-hour technical deep-dive with CTO and IT team","Define PoC success criteria and hospital selection together"]',
    0.91)
ON CONFLICT (session_id) DO NOTHING;

END $$;
