-- ============================================================
-- Sample Knowledge Seed — Text data only (no embeddings).
--
-- PURPOSE: Manual reference / schema demo.
-- FOR AUTO-SEEDING WITH EMBEDDINGS: the KnowledgeSeederService
--   ingests medplat_knowledge.txt on first startup automatically
--   when GEMINI_API_KEY is set and the table is empty.
-- ============================================================

-- Run after V4 migration: psql -U postgres -d meetwise -f knowledge_seed.sql

INSERT INTO knowledge_chunks (title, source_type, source_name, chunk_text, metadata) VALUES
(
  'MEDplat Platform Overview',
  'PRODUCT_KNOWLEDGE',
  'manual_seed',
  'MEDplat is an AI-powered digital health platform connecting patients, doctors, and hospitals. It delivers end-to-end clinical workflow automation using HL7 FHIR APIs, telemedicine, AI-assisted diagnostics, and an offline-first architecture optimized for India''s healthcare landscape. Key modules include HIS, EHR, Telemedicine, AI Diagnostics, Pharmacy, LIS, and mobile apps for patients and doctors.',
  '{"category":"overview","seeded_by":"manual"}'
),
(
  'Common Objections — Cost',
  'OBJECTION_RESPONSES',
  'manual_seed',
  'Objection: Budget is tight or cost is too high. Response: MEDplat SaaS model eliminates upfront infrastructure investment. TCO is 30–40% lower than on-premise over 5 years. ROI studies show: 2.5 FTE saved in administration, 18% reduction in medication errors, 6-hour shorter discharge cycles, 8–12% bed occupancy increase. We offer flexible payment and government subsidy linkage under PMIS/Ayushman Bharat where applicable.',
  '{"category":"objection","type":"cost"}'
),
(
  'Common Objections — Implementation Disruption',
  'OBJECTION_RESPONSES',
  'manual_seed',
  'Objection: Implementation will disrupt daily hospital operations. Response: MEDplat uses zero-downtime shadow-mode deployment. Average implementation for 300-bed hospital is 12 weeks. We assign a dedicated implementation manager, provide on-site training, and offer 6-month hypercare post go-live. Over 60% of clients ran parallel systems 3–6 months during transition.',
  '{"category":"objection","type":"implementation"}'
),
(
  'Common Objections — Data Security',
  'OBJECTION_RESPONSES',
  'manual_seed',
  'Objection: Concerned about data security and patient privacy. Response: MEDplat holds SOC 2 Type II certification, annual third-party penetration tests, AES-256 encryption at rest, TLS 1.3 in transit. Data remains in your hospital''s residency zone. DPDP Act-compliant consent management. We never access patient data without explicit hospital consent.',
  '{"category":"objection","type":"security"}'
),
(
  'Meeting Strategy — CEO Level',
  'MEETING_STRATEGY',
  'manual_seed',
  'For CEO stakeholders: Open with their strategic priorities (accreditation, expansion, government empanelment). Frame MEDplat as a platform not a product — a data advantage, not just software. Lead with peer adoption stories from comparable hospitals. Use the 90-day pilot offer to reduce perceived risk. Propose a discovery workshop with CIO and CMO as the next step to build internal champions. Expect cost and implementation objections first.',
  '{"category":"meeting_strategy","stakeholder":"CEO"}'
),
(
  'ABDM and Interoperability',
  'DOMAIN_KNOWLEDGE',
  'manual_seed',
  'MEDplat is ABDM (Ayushman Bharat Digital Mission) compliant. Supports ABHA ID creation, health record linking, and health locker integration. FHIR R4 APIs enable integration with state HMIS, insurance portals, and diagnostic labs. Standard ABDM onboarding takes 4–6 weeks. Supports SNOMED CT, ICD-10, LOINC, and RxNorm terminologies. Hospitals gain access to Ayushman Bharat empanelment and government referral networks upon ABDM compliance.',
  '{"category":"interoperability","standard":"ABDM-FHIR"}'
),
(
  'Offline-First Architecture',
  'DOMAIN_KNOWLEDGE',
  'manual_seed',
  'MEDplat offline-first design keeps clinical operations running without internet. Local edge devices synchronize in real time when online and queue writes offline. Critical for tier-2/3 cities and PHCs with unreliable connectivity. Offline capabilities cover: registration, vitals, prescriptions, lab entries, and billing. Data sync uses conflict-resolution with timestamp precedence and clinician override to prevent data loss.',
  '{"category":"architecture","feature":"offline-first"}'
),
(
  'ROI and Financial Positioning',
  'PARTNERSHIP_KNOWLEDGE',
  'manual_seed',
  'MEDplat ROI timeline: payback period 18–24 months. Revenue uplift sources: increased outpatient volume via telemedicine, faster billing cycles (98% first-pass claim clearance vs 78% industry average), new service lines from AI diagnostics. Cost savings: reduced paper administration averaging 2.5 FTE, 18% medication error reduction, 6-hour shorter discharge cycles, 8–12% bed occupancy improvement. Pilot program available: 90-day free pilot for single department to validate KPIs before long-term commitment.',
  '{"category":"financial","type":"roi_positioning"}'
);

-- NOTE: embedding column is NULL in these rows. The KnowledgeSeederService
-- auto-generates embeddings from medplat_knowledge.txt on first startup.
-- Run this SQL only if you want to inspect the table structure manually.
