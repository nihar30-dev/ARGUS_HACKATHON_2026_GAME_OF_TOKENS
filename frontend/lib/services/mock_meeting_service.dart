import 'dart:convert';

import '../config/app_config.dart';
import '../models/session_response.dart';

// Agent name constants — must match backend AgentRun.agentName values exactly
const _kOrgResearch = 'OrganizationResearchAgent';
const _kStakeholder = 'StakeholderPersonaAgent';
const _kEngagement = 'EngagementStrategyAgent';
const _kObjection = 'ObjectionPredictionAgent';
const _kCritic = 'CriticValidatorAgent';
const _kSynthesis = 'FinalSynthesisAgent';

/// Offline demo data for the Apollo Hospitals / MEDplat scenario.
///
/// Returns a fully-populated [SessionResponse] that mirrors what the real
/// pipeline would produce, including 10 directional [AgentTrace] links that
/// clearly show how each agent's output shaped the next.
///
/// Key demo story visible in the traces:
///   [CriticValidatorAgent] flags the "100% interoperability" claim in
///   [ObjectionPredictionAgent]'s response → [FinalSynthesisAgent] revises
///   the claim to a specific, defensible connector-status statement.
///
/// Usage:
///   final session = MockMeetingService.buildApolloSession();
///   // or with simulated latency:
///   final session = await MockMeetingService().runDemo();
class MockMeetingService {
  /// Async wrapper with simulated latency so the loading UI renders.
  ///
  /// Delay duration is controlled by [AppConfig.mockDelay].
  /// Override [simulatedDelay] only in tests (pass [Duration.zero]).
  Future<SessionResponse> runDemo({
    Duration? simulatedDelay,
  }) async {
    final delay = simulatedDelay ?? AppConfig.mockDelay;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return buildApolloSession();
  }

  Future<SessionResponse> getSession(String id) async => buildApolloSession();

  // ── Public factory ─────────────────────────────────────────────────────────

  static SessionResponse buildApolloSession() => SessionResponse(
        sessionId: 'demo-apollo-001',
        organizationName: 'Apollo Hospitals',
        meetingObjective: 'Discuss MEDplat digital health platform partnership',
        stakeholderRole: 'CEO',
        status: 'COMPLETED',
        agentRuns: _buildRuns(),
        traces: _buildTraces(),
        finalReport: _buildReport(),
      );

  // ── Agent Runs ─────────────────────────────────────────────────────────────

  static List<AgentRun> _buildRuns() => [
        _orgResearchRun(),
        _stakeholderRun(),
        _engagementRun(),
        _objectionRun(),
        _criticRun(),
        _synthesisRun(),
      ];

  static AgentRun _orgResearchRun() => AgentRun(
        agentName: _kOrgResearch,
        executionOrderIndex: 1,
        inputJson: jsonEncode({
          'organizationName': 'Apollo Hospitals',
          'meetingObjective': 'Discuss MEDplat digital health platform partnership',
          'offeringDescription': 'MEDplat open-source configurable digital health platform',
          'stakeholderRole': 'CEO',
        }),
        outputJson: jsonEncode({
          'agent': _kOrgResearch,
          'influencedBy': [],
          'confidenceScore': 0.88,
          'organizationSummary':
              "Apollo Hospitals is India's largest integrated healthcare provider — 71 hospitals across 9 states, 10,000+ beds, FY25 revenue ₹18,000 Cr. The board has earmarked ₹2,400 Cr for digital transformation by FY2026. Currently operates three disparate EMR systems (Philips TASY, McKesson Paragon, and a proprietary in-house platform) creating critical interoperability gaps that affect patient continuity and ABDM compliance readiness.",
          'painPoints': [
            'Fragmented patient records across 71 hospitals — no unified patient identity layer',
            'ABDM/NHIX certification deadline: December 2025 — 6 months away',
            'Legacy EMR vendor licensing costing an estimated ₹180 Cr/year across all three systems',
            '3 EMR systems generate 9 point-to-point integration touchpoints — high maintenance overhead',
            'New CTO mandate: reduce IT fragmentation within 18 months of appointment (Feb 2025)',
          ],
          'opportunities': [
            'Unified patient data platform targeting 50 Lakh active patients on Apollo 24/7 app',
            'ABDM compliance acceleration — 90-day sprint vs Apollo internal estimate of 18 months',
            '40% reduction in cross-site data reconciliation overhead via FHIR-native unification',
            'Elimination of ₹180 Cr annual EMR licensing exposure through open-source core',
          ],
          'recentSignals': [
            '₹600 Cr digital investment Q3 FY25 — IT modernization is board-level priority',
            'New CTO (ex-Google Health) hired February 2025 — open-source architecture is familiar ground',
            'NHIX certification mandated by ABDM by December 2025 — compliance urgency is real',
            'Apollo 24/7 crossed 10M downloads — digital scale is proven; data layer is the gap',
          ],
        }),
        confidenceScore: 0.88,
        influencedBy: const [],
        usedGemini: true,
        executionMs: 2340,
      );

  static AgentRun _stakeholderRun() => AgentRun(
        agentName: _kStakeholder,
        executionOrderIndex: 2,
        inputJson: jsonEncode({
          'organizationResearch': {
            'summary':
                '71-hospital network, ₹2,400 Cr digital budget, 3 disparate EMRs (TASY + McKesson + proprietary)',
            'painPoints': [
              'Fragmented records',
              'ABDM deadline Dec 2025',
              'EMR vendor lock-in ₹180 Cr/yr',
            ],
            'recentSignals': [
              'New CTO ex-Google Health',
              'NHIX deadline Dec 2025',
              '₹600 Cr Q3 FY25 investment',
            ],
          },
        }),
        outputJson: jsonEncode({
          'agent': _kStakeholder,
          'influencedBy': [_kOrgResearch],
          'confidenceScore': 0.91,
          'personaType': 'Strategic Visionary',
          'stakeholderRole': 'CEO',
          'priorities': [
            'Patient outcome improvement at scale — proof via metrics, not claims',
            'ABDM/NHIX regulatory compliance — hard gate, non-negotiable before scaling',
            'ROI demonstrable within 18 months — aligned to board reporting cycle',
            'Vendor SLA reliability — previous legacy vendor failures created institutional risk aversion',
            'Open-source credibility — new CTO will scrutinize architecture choices and community backing',
          ],
          'communicationStyle':
              'Executive summary first, data-backed throughout. Dislikes vendor jargon and technical deep-dives without business context. Responds well to peer hospital case studies and quantified outcomes. Effective attention window: 20 minutes.',
          'decisionLens':
              'ROI-first with regulatory compliance as a hard gate. Will not commit without a defined pilot model, clear exit terms, and CTO technical sign-off.',
          'riskProfile':
              'Moderate-conservative. Direct involvement in a ₹240 Cr EMR migration write-off in 2022 has made large-scale platform changes emotionally loaded. Needs proof before scale — a contained pilot with rollback terms addresses this.',
          'keyTriggers': [
            'Peer hospital case study at comparable scale (50+ hospitals)',
            'Defined implementation timeline with measurable milestones',
            'Clear data sovereignty architecture — Apollo data never leaves Apollo infrastructure',
            'Open-source governance model and named enterprise support team',
            'CTO pre-alignment before CEO final decision',
          ],
          'avoidancePatterns': [
            'Technical deep-dives without business framing',
            'Vague timelines or "it depends" answers',
            'References to startup scale — Apollo needs enterprise credentials',
            'Minimizing the 2022 migration failure — acknowledge it directly',
          ],
        }),
        confidenceScore: 0.91,
        influencedBy: const [_kOrgResearch],
        usedGemini: false,
        executionMs: 48,
      );

  static AgentRun _engagementRun() => AgentRun(
        agentName: _kEngagement,
        executionOrderIndex: 3,
        inputJson: jsonEncode({
          'organizationResearch': {
            'summary': '71-hospital network, ABDM compliance urgency, new CTO (ex-Google Health)',
            'opportunities': ['ABDM 90-day sprint', '40% reconciliation reduction', '₹180 Cr licensing elimination'],
          },
          'stakeholderPersona': {
            'personaType': 'Strategic Visionary',
            'decisionLens': 'ROI-first with compliance hard gate',
            'riskProfile': 'Moderate-conservative — burned by 2022 EMR write-off',
            'keyTriggers': ['Peer case studies', 'Defined pilot model', 'Data sovereignty guarantee'],
          },
        }),
        outputJson: jsonEncode({
          'agent': _kEngagement,
          'influencedBy': [_kOrgResearch, _kStakeholder],
          'confidenceScore': 0.85,
          'meetingGoal':
              'Secure CEO commitment to a 3-hospital 90-day ABDM compliance pilot with defined success metrics and a CTO technical discovery call as the formal next step.',
          'openingPositioning':
              "Lead with Apollo's EMR fragmentation cost burden (₹180 Cr/yr licensing). Position MEDplat as a FHIR-native unification layer built on open standards — not another vendor system to procure, manage, or be locked into.",
          'valueProposition':
              'Three quantified outcomes: (1) ABDM/NHIX compliance in 90 days vs Apollo internal estimate of 18 months, (2) 40% reduction in cross-site data reconciliation overhead, (3) elimination of ₹180 Cr annual licensing exposure through the open-source core.',
          'conversationSequence': [
            'Open with cost-quantification question: "How much is multi-site record reconciliation costing today?"',
            'Validate ABDM compliance timeline pressure — December 2025 is 6 months away',
            'Present Apollo Health Network case study — comparable scale, 90-day ABDM sprint outcome',
            'Introduce modular pilot: 1 metro hospital + 1 Tier-2 city + 1 specialty center',
            'Anchor next step on CTO alignment — propose technical discovery call',
          ],
          'toneGuidance':
              'Peer-to-peer executive dialogue. Mirror Apollo investment language (₹Cr scale). Avoid product demo mode — frame this as a strategic partnership conversation, not a sales pitch.',
        }),
        confidenceScore: 0.85,
        influencedBy: const [_kOrgResearch, _kStakeholder],
        usedGemini: true,
        executionMs: 1890,
      );

  static AgentRun _objectionRun() => AgentRun(
        agentName: _kObjection,
        executionOrderIndex: 4,
        inputJson: jsonEncode({
          'organizationResearch': {
            'emrSystems': ['Philips TASY', 'McKesson Paragon', 'proprietary in-house'],
            'recentSignals': ['New CTO ex-Google Health — technically deep'],
          },
          'stakeholderPersona': {
            'riskProfile': 'Moderate-conservative — ₹240 Cr 2022 EMR write-off',
            'decisionLens': 'ROI-first with compliance hard gate',
          },
          'engagementStrategy': {
            'openingPositioning': 'MEDplat as federation layer over TASY and McKesson — not a new EMR',
          },
        }),
        outputJson: jsonEncode({
          'agent': _kObjection,
          'influencedBy': [_kOrgResearch, _kStakeholder, _kEngagement],
          'confidenceScore': 0.82,
          'predictedObjections': [
            {
              'objection': 'How do we guarantee patient data stays within Apollo infrastructure?',
              'likelihood': 0.94,
              'severity': 'HIGH',
              'response':
                  "MEDplat is architected for on-premise and private-cloud deployment. Zero patient data transits our infrastructure — we provide the software layer only. Apollo retains full data sovereignty with cryptographic audit logs. We can provide a security architecture review with your team before the pilot begins.",
            },
            {
              'objection': 'We already run 3 EMR systems. Adding another layer increases complexity.',
              'likelihood': 0.88,
              'severity': 'HIGH',
              'response':
                  'MEDplat is not a 4th EMR — it is a FHIR-native interoperability layer. Philips TASY and McKesson Paragon continue operating unchanged. MEDplat reduces your integration topology from 9 point-to-point connections to 3 standardised FHIR adapters. Net complexity decreases.',
            },
            {
              'objection': 'What guarantees interoperability with all our current vendor systems?',
              'likelihood': 0.81,
              'severity': 'MEDIUM',
              'response':
                  'MEDplat supports 100% interoperability with all major EMR vendors through standardised HL7 FHIR connectors.',
            },
            {
              'objection': 'Open-source means no dedicated support — who do we call at 2 AM?',
              'likelihood': 0.75,
              'severity': 'MEDIUM',
              'response':
                  'Our enterprise tier includes 24/7 named support, a 4-hour critical SLA, and a dedicated Customer Success Engineer embedded during the pilot phase. The open-source community (200+ contributors) also means faster bug resolution than any single vendor.',
            },
            {
              'objection': 'We had a failed EMR migration in 2022. What makes this different?',
              'likelihood': 0.68,
              'severity': 'HIGH',
              'response':
                  'The 2022 failure was a rip-and-replace migration — data moved, systems decommissioned, staff retrained. MEDplat does none of that. Your EMRs continue running. MEDplat federates them through a new API layer. Pilot risk is contained to 3 hospitals with a 90-day rollback guarantee.',
            },
          ],
        }),
        confidenceScore: 0.82,
        influencedBy: const [_kOrgResearch, _kStakeholder, _kEngagement],
        usedGemini: true,
        executionMs: 1650,
      );

  static AgentRun _criticRun() => AgentRun(
        agentName: _kCritic,
        executionOrderIndex: 5,
        inputJson: jsonEncode({
          'collatedContext':
              'OrgResearch + StakeholderPersona + EngagementStrategy + ObjectionPrediction outputs',
        }),
        outputJson: jsonEncode({
          'agent': _kCritic,
          'influencedBy': [_kOrgResearch, _kStakeholder, _kEngagement, _kObjection],
          'confidenceScore': 0.78,
          'validationStatus': 'ISSUES_FOUND',
          'contradictions': [],
          'unsupportedClaims': [
            {
              'claim':
                  'MEDplat supports 100% interoperability with all major EMR vendors through standardised HL7 FHIR connectors.',
              'location': '$_kObjection — objection 3 response',
              'issue':
                  'Research data confirms Apollo runs Philips TASY and McKesson Paragon. No evidence in available data confirms production-ready FHIR connectors exist for both. The new CTO (ex-Google Health) is technically deep — an absolute "100%" claim will be immediately challenged. If it cannot be substantiated in the room, credibility is lost at a critical moment.',
              'recommendation':
                  'Revise to: MEDplat is FHIR R4-compliant with a modular connector framework. Be specific: state Philips TASY connector status (production/beta) and McKesson Paragon connector status separately. Never use "100%" without per-vendor evidence.',
              'riskLevel': 'HIGH',
            },
          ],
          'strengthValidations': [
            'ABDM/NHIX compliance in 90-day sprint is consistent with documented MEDplat ABDM module capabilities — claim is defensible.',
            'On-premise deployment claim is architecturally credible for an open-source platform — claim is accurate.',
            '40% reconciliation cost reduction is within published healthcare interoperability benchmark range (35–45%) — claim is supportable.',
            '9-to-3 connector reduction is mathematically correct for a 3-system hub-and-spoke topology — claim is precise and verifiable.',
            '2022 migration failure framing as rip-and-replace vs federation is an accurate and emotionally intelligent distinction — retain it.',
          ],
          'overallAssessment':
              'Strategy is well-targeted and the persona calibration is accurate. One HIGH-risk claim — the absolute interoperability assertion — must be revised before the meeting. All other responses are factually defensible. Confidence docked to 0.78 pending that revision.',
        }),
        confidenceScore: 0.78,
        influencedBy: const [_kOrgResearch, _kStakeholder, _kEngagement, _kObjection],
        usedGemini: false,
        executionMs: 112,
      );

  static AgentRun _synthesisRun() => AgentRun(
        agentName: _kSynthesis,
        executionOrderIndex: 6,
        inputJson: jsonEncode({
          'collatedContext': 'Full pipeline context including CriticValidator revisions',
          'criticValidatorFindings': '100% interoperability claim revised per HIGH-risk flag',
        }),
        outputJson: jsonEncode({
          'agent': _kSynthesis,
          'influencedBy': [_kOrgResearch, _kStakeholder, _kEngagement, _kObjection, _kCritic],
          'confidenceScore': 0.87,
          'criticValidatorIncorporated': true,
          'revisedClaim':
              'Interoperability response revised per CriticValidator flag: replaced absolute "100%" claim with specific connector-status statement — TASY connector production-ready, McKesson Paragon connector in beta with 30-day GA timeline.',
          'executiveBrief':
              "Apollo Hospitals operates 71 hospitals across 9 states with three incompatible EMR systems generating a ₹180 Cr annual integration overhead and an ABDM compliance deadline 6 months away. MEDplat enters as a FHIR-native federation layer — not a replacement — that unifies existing systems through a common API surface, reducing the integration topology from 9 point-to-point connections to 3 standardised FHIR adapters. The proposed pilot targets 3 hospitals (1 metro flagship, 1 Tier-2 city, 1 specialty centre) with a 90-day ABDM compliance sprint as the proof milestone. The CEO's risk profile — shaped by a ₹240 Cr EMR write-off in 2022 — is directly addressed through a zero-migration architecture and a 90-day rollback guarantee. CTO technical alignment via a dedicated discovery call is the critical next step before any pilot commitment. CriticValidator revision applied: the interoperability response now specifies Philips TASY connector (production-ready) and McKesson Paragon connector (beta, 30-day GA) rather than an unsupported absolute claim.",
        }),
        confidenceScore: 0.87,
        influencedBy: const [_kOrgResearch, _kStakeholder, _kEngagement, _kObjection, _kCritic],
        usedGemini: true,
        executionMs: 2890,
      );

  // ── Agent Traces (directional influence links) ─────────────────────────────

  static List<AgentTrace> _buildTraces() => [
        // 1. OrgResearch → StakeholderPersona
        AgentTrace(
          sourceAgent: _kOrgResearch,
          targetAgent: _kStakeholder,
          inputSummary:
              'Apollo 71-hospital profile, ₹240 Cr 2022 EMR write-off, ABDM Dec 2025 deadline, new CTO (ex-Google Health)',
          outputSummary:
              'CEO persona: Strategic Visionary, ROI-first decision lens, moderate-conservative risk (institutional trauma from 2022 write-off)',
          influenceDescription:
              "The 2022 EMR write-off surfaced by OrgResearch elevated risk-aversion in the CEO persona to 'high-consequence' level. Without this specific data point, the persona would have applied a generic hospital-CEO risk profile. The write-off shaped which guarantees and proof points the Stakeholder agent prioritised — most notably the rollback clause and the contained pilot model.",
        ),

        // 2. OrgResearch → EngagementStrategy
        AgentTrace(
          sourceAgent: _kOrgResearch,
          targetAgent: _kEngagement,
          inputSummary:
              'EMR pain: 3 systems, ₹180 Cr/yr licensing, 9 integration touchpoints, ABDM deadline 6 months away',
          outputSummary:
              'Opening positioning anchored on ₹180 Cr licensing exposure; ABDM 90-day sprint as urgency hook',
          influenceDescription:
              'The specific ₹180 Cr annual licensing figure from OrgResearch became the financial anchor for the engagement opening. Without this number, the strategy would have opened with generic platform benefits. The ABDM December 2025 deadline gave EngagementStrategy the urgency framing that made the 90-day sprint a time-sensitive offer rather than a generic proof-of-concept.',
        ),

        // 3. OrgResearch → ObjectionPrediction
        AgentTrace(
          sourceAgent: _kOrgResearch,
          targetAgent: _kObjection,
          inputSummary: 'Specific EMR vendors: Philips TASY + McKesson Paragon + proprietary in-house',
          outputSummary:
              'Interoperability objection rated HIGH likelihood; vendor-specific connector question anticipated',
          influenceDescription:
              "Knowing Apollo's exact EMR vendors allowed ObjectionPrediction to frame the interoperability objection as vendor-specific (TASY + McKesson) rather than generic. This precision later became the source of CriticValidator's most critical finding — the 100% interoperability claim was plausible in general but unsupported for these two specific systems.",
        ),

        // 4. StakeholderPersona → EngagementStrategy
        AgentTrace(
          sourceAgent: _kStakeholder,
          targetAgent: _kEngagement,
          inputSummary:
              'CEO: 20-minute attention window, peer case studies as key trigger, ROI-first framing required, no technical jargon',
          outputSummary:
              'Conversation sequence restructured: case study moved earlier, technical architecture overview removed entirely',
          influenceDescription:
              "The Stakeholder persona's 20-minute effective attention window directly reshaped the conversation sequence — the Apollo Health Network case study was moved from step 4 to step 3, and a planned technical architecture overview was removed entirely. Without the persona's attention-window constraint, the strategy would have included content Apollo's CEO would tune out.",
        ),

        // 5. StakeholderPersona → ObjectionPrediction
        AgentTrace(
          sourceAgent: _kStakeholder,
          targetAgent: _kObjection,
          inputSummary:
              'Risk profile: Moderate-conservative, ₹240 Cr 2022 EMR write-off, high emotional weight on migration failures',
          outputSummary:
              'Objection 5 added: "What makes this different from 2022?" — rated HIGH severity despite lower base likelihood',
          influenceDescription:
              "The 2022 EMR failure in the CEO persona triggered an objection not present in generic hospital scenarios. ObjectionPrediction rated it HIGH severity despite a 0.68 likelihood score because the CEO's direct involvement makes it emotionally loaded — a weak or dismissive response here ends the conversation regardless of everything else.",
        ),

        // 6. EngagementStrategy → ObjectionPrediction
        AgentTrace(
          sourceAgent: _kEngagement,
          targetAgent: _kObjection,
          inputSummary: 'Positioning: MEDplat as FHIR federation layer over TASY and McKesson — not a new EMR',
          outputSummary:
              'Objection 2 response uses 9-to-3 connector reduction math derived directly from the federation framing',
          influenceDescription:
              'The "unification layer, not replacement" framing from EngagementStrategy enabled ObjectionPrediction to construct a precise mathematical counter (9 point-to-point → 3 FHIR adapters) rather than a generic reassurance. The framing and the counter-argument are logically coupled — without the federation positioning, the math would not apply.',
        ),

        // 7. ObjectionPrediction → CriticValidator (source of the key finding)
        AgentTrace(
          sourceAgent: _kObjection,
          targetAgent: _kCritic,
          inputSummary:
              'Objection 3 response: "MEDplat supports 100% interoperability with all major EMR vendors through standardised HL7 FHIR connectors."',
          outputSummary:
              'HIGH-risk flag: 100% interoperability claim is unsupported for Philips TASY and McKesson Paragon specifically',
          influenceDescription:
              "The absolute '100% interoperability' claim in ObjectionPrediction's response to objection 3 was the primary finding of CriticValidator's review. Cross-referencing against the specific EMR vendors identified by OrgResearch, CriticValidator determined the claim cannot be substantiated in the meeting room and flagged it as a HIGH-risk credibility failure point with a technically-informed CEO.",
        ),

        // 8. EngagementStrategy → CriticValidator
        AgentTrace(
          sourceAgent: _kEngagement,
          targetAgent: _kCritic,
          inputSummary:
              'Claims: ABDM compliance in 90 days, 40% reconciliation cost reduction, open-source eliminates lock-in',
          outputSummary: 'All three claims validated — within documented capability range and industry benchmarks',
          influenceDescription:
              "CriticValidator cross-checked EngagementStrategy's three quantified claims against OrgResearch data and public healthcare interoperability benchmarks. All three passed. This gave FinalSynthesis confidence to state these numbers without hedging — they are accurate and defensible.",
        ),

        // 9. CRITICAL STORY: CriticValidator → FinalSynthesis
        AgentTrace(
          sourceAgent: _kCritic,
          targetAgent: _kSynthesis,
          inputSummary:
              'HIGH-risk flag: "100% interoperability" — unsupported for TASY and McKesson specifically. Recommendation: replace with per-vendor connector status.',
          outputSummary:
              'Objection 3 response revised: FHIR R4-compliant with modular connectors — TASY production-ready, McKesson beta (30-day GA). Absolute claim removed.',
          influenceDescription:
              "This is the pivotal interdependency in the pipeline. CriticValidator's flag prevented a credibility failure in front of a technically-informed ex-Google Health CTO. FinalSynthesis incorporated the specific revision — replacing the absolute claim with connector-level specifics per vendor — producing a response that is both accurate and more compelling than the original. Without CriticValidator, the final brief would have contained a factually questionable claim that the CEO's new CTO would immediately challenge, potentially ending the partnership conversation.",
        ),

        // 10. OrgResearch → FinalSynthesis
        AgentTrace(
          sourceAgent: _kOrgResearch,
          targetAgent: _kSynthesis,
          inputSummary:
              'Apollo 71-hospital scale, 9-state footprint, ₹2,400 Cr digital budget, ₹180 Cr licensing burden, ABDM Dec 2025',
          outputSummary:
              'Executive brief opens with Apollo-specific financial stakes rather than generic healthcare platform framing',
          influenceDescription:
              "OrgResearch's specific data points — 71 hospitals, ₹180 Cr annual licensing exposure, 9-to-3 topology reduction — are embedded verbatim in the executive brief opening. FinalSynthesis used these to frame the financial stakes before introducing MEDplat, making the brief organisation-specific rather than a template. A CEO reads the brief and immediately recognises their own situation.",
        ),
      ];

  // ── Final Report ───────────────────────────────────────────────────────────

  static FinalReport _buildReport() => FinalReport(
        overallConfidence: 0.87,
        doAndDontJson: jsonEncode({
          'dos': [
            "Lead with the ₹180 Cr annual licensing burden — let Apollo quantify their own pain first",
            "Reference the 2022 EMR write-off proactively and explain why this approach is different",
            "Present the peer hospital case study at step 3, before any product description",
            "Frame MEDplat as a FHIR federation layer over existing EMRs — not a replacement or 4th system",
            "Offer a dedicated CTO technical discovery call as the single specific next-step ask",
            "Be specific on connector status: TASY (production-ready), McKesson Paragon (beta, 30-day GA)",
          ],
          'donts': [
            "Use '100% interoperability' — CriticValidator revised this to per-vendor connector specifics",
            "Lead with product demos or technical architecture without business context framing",
            "Reference startup-scale deployments — Apollo operates at 71-hospital enterprise scale",
            "Give vague timelines or 'it depends on scoping' non-answers",
            "Sidestep or minimise the 2022 migration failure — acknowledge it directly and immediately",
            "Push for contract commitment in the first meeting — the CTO discovery call is the only ask",
          ],
        }),
        executiveBrief:
            "Apollo Hospitals operates 71 hospitals across 9 states with three incompatible EMR systems generating a ₹180 Cr annual integration overhead and an ABDM compliance deadline 6 months away. MEDplat enters as a FHIR-native federation layer — not a replacement — unifying existing systems through a common API surface and reducing the integration topology from 9 point-to-point connections to 3 standardised FHIR adapters. The proposed pilot targets 3 hospitals (1 metro flagship, 1 Tier-2 city, 1 specialty centre) with a 90-day ABDM compliance sprint as the proof milestone. The CEO's risk profile — shaped by a ₹240 Cr EMR write-off in 2022 — is addressed through a zero-migration architecture and a 90-day rollback guarantee. CTO alignment via a technical discovery call is the critical next step. Note: CriticValidator revised the interoperability response — the final version states per-vendor connector status (TASY: production-ready; McKesson: beta, 30-day GA) rather than the original unsupported absolute claim.",
        conversationFlowJson: jsonEncode([
          {
            'phase': 'Pain Point Validation',
            'duration': '5 min',
            'approach':
                "Open with a cost-quantification question: 'How much is reconciling patient records across your 71 hospitals costing today?' Let Apollo quantify the pain before introducing MEDplat.",
          },
          {
            'phase': 'Compliance Urgency',
            'duration': '5 min',
            'approach':
                "Validate the ABDM/NHIX December 2025 deadline. 'What does your current compliance timeline look like?' Surface that the internal estimate is 18 months against a 6-month window — create urgency without manufacturing it.",
          },
          {
            'phase': 'Peer Proof Point',
            'duration': '8 min',
            'approach':
                'Present the Apollo Health Network case study — comparable scale (50+ hospitals), 90-day ABDM sprint outcome, zero EMR migration. Let the numbers speak. Do not show a product demo in this slot.',
          },
          {
            'phase': 'Partnership Framing',
            'duration': '5 min',
            'approach':
                "Introduce MEDplat as a federation layer, not a vendor product. Emphasise open-source governance, zero lock-in, and the FHIR R4 open-standards foundation. Reference the new CTO's open-source background naturally.",
          },
          {
            'phase': 'Objection Handling',
            'duration': '8 min',
            'approach':
                'Expect data sovereignty, complexity, and interoperability questions in that order. Be specific on connector status — TASY is production-ready; McKesson is 30-day beta GA. Do not use the word "100%" — state per-vendor facts.',
          },
          {
            'phase': 'Pilot Proposal',
            'duration': '5 min',
            'approach':
                'Propose the 3-hospital pilot: 1 metro flagship, 1 Tier-2 city, 1 specialty centre. 90-day ABDM sprint with a rollback guarantee. Success metric: ABDM certification + measurable reconciliation-time reduction.',
          },
          {
            'phase': 'Next Steps',
            'duration': '2 min',
            'approach':
                'Close with two asks only: (1) Technical discovery call with CTO + IT team within 2 weeks. (2) Access to one hospital EMR topology for connector scoping. One meeting at a time.',
          },
        ]),
        questionsJson: jsonEncode([
          "What is Apollo's current estimated cost to reconcile patient records across all 71 hospitals annually?",
          'Where does the ABDM certification timeline stand today, and what is the internal estimate for completion?',
          "Has the new CTO assessed the current 3-EMR architecture? What is their stated direction?",
          "What does a successful 90-day pilot look like from the board's perspective — what metrics would trigger a scale decision?",
          'Which hospital in the Apollo network would be the ideal starting point for a pilot, and why?',
          'Has Apollo evaluated any open-source health platforms previously? What was the outcome?',
          'What is the data governance policy for cross-hospital patient identity — who owns the unified patient record?',
        ]),
        objectionResponsesJson: jsonEncode([
          {
            'objection': 'How do we guarantee patient data stays within Apollo infrastructure?',
            'severity': 'HIGH',
            'response':
                "MEDplat is architected for on-premise and private-cloud deployment. Zero patient data transits our infrastructure — we provide the software layer only. Apollo retains full data sovereignty with cryptographic audit logs. We can arrange a security architecture review with your team before the pilot agreement is signed.",
          },
          {
            'objection': 'We already run 3 EMR systems. Adding another layer increases complexity.',
            'severity': 'HIGH',
            'response':
                'MEDplat is not a 4th EMR — it is a FHIR-native interoperability layer. Philips TASY and McKesson Paragon continue operating unchanged. MEDplat reduces your integration topology from 9 point-to-point connections to 3 standardised FHIR adapters. Net complexity decreases, not increases.',
          },
          {
            'objection': 'What guarantees interoperability with Philips TASY and McKesson Paragon specifically?',
            'severity': 'MEDIUM',
            'criticRevised': true,
            'response':
                'The Philips TASY FHIR connector is production-ready and deployed in 4 hospital networks. The McKesson Paragon connector is currently in beta with a 30-day GA timeline. We will scope both in the technical discovery call and provide a specific integration timeline before the pilot agreement is signed.',
          },
          {
            'objection': 'Open-source means no dedicated support — who do we call at 2 AM?',
            'severity': 'MEDIUM',
            'response':
                'Our enterprise tier includes a named 24/7 support team, a 4-hour critical SLA, and a dedicated Customer Success Engineer embedded during the pilot phase. The open-source community (200+ contributors) also means faster bug resolution than any single-vendor product.',
          },
          {
            'objection': 'We had a failed EMR migration in 2022. What makes this different?',
            'severity': 'HIGH',
            'response':
                'The 2022 failure was a rip-and-replace migration — data moved, systems decommissioned, staff retrained on new interfaces. MEDplat does none of that. Your existing EMRs continue running exactly as they do today. MEDplat federates them through a new API layer above. Pilot risk is contained to 3 hospitals with a 90-day rollback guarantee — if the pilot metrics are not met, we exit cleanly.',
          },
        ]),
        nextStepsJson: jsonEncode([
          'Schedule technical discovery call with Apollo CTO and IT architecture team within 2 weeks',
          'Request EMR topology documentation for one pilot hospital (Philips TASY instance preferred) for connector scoping',
          'Share the Apollo Health Network ABDM compliance case study and sprint report within 48 hours of this meeting',
          'Prepare MEDplat data sovereignty architecture diagram tailored to Apollo private-cloud setup',
          'Draft 3-hospital pilot scope document with 90-day ABDM sprint milestones, success metrics, and rollback terms',
          'Align with Apollo CTO on McKesson Paragon connector beta timeline and GA readiness criteria',
        ]),
      );
}
