import 'session_response.dart';

/// View model for one agent's slot in the execution pipeline.
///
/// Combines data from [AgentRun] (execution details, confidence, input/output)
/// with [AgentTrace] links (which agents fed into this one and which ones it
/// influenced next). Use [AgentTraceModel.fromAgentRun] to build the full list
/// from a [SessionResponse].
///
/// JSON field mapping:
///   inputReceived      ↔  "inputJson"            (AgentRunDTO)
///   outputGenerated    ↔  "outputJson"            (AgentRunDTO)
///   influencedBy       ↔  "influencedBy"          (AgentRunDTO — comma list)
///   influencesNext     ↔  derived from AgentTraceDTO.targetAgent
///   traceSummary       ↔  AgentTraceDTO.influenceDescription (first inbound)
class AgentTraceModel {
  final String? id;
  final String agentName;

  /// 1-based position in the pipeline.
  final int order;

  /// Raw JSON string received as this agent's input context.
  final String? inputReceived;

  /// Raw JSON string produced by this agent.
  final String? outputGenerated;

  final double confidenceScore;

  /// Names of agents that contributed input to this agent.
  final List<String> influencedBy;

  /// Names of agents that this agent's output fed into.
  final List<String> influencesNext;

  /// Human-readable summary of how inbound influence shaped this agent's work.
  final String? traceSummary;

  final bool usedGemini;
  final int executionMs;

  const AgentTraceModel({
    this.id,
    required this.agentName,
    required this.order,
    this.inputReceived,
    this.outputGenerated,
    required this.confidenceScore,
    this.influencedBy = const [],
    this.influencesNext = const [],
    this.traceSummary,
    required this.usedGemini,
    this.executionMs = 0,
  });

  // ── Factory: build from session data ──────────────────────────────────────

  /// Creates an [AgentTraceModel] for [run] using [allTraces] to compute
  /// outbound influence links and inbound trace summaries.
  factory AgentTraceModel.fromAgentRun(
    AgentRun run,
    List<AgentTrace> allTraces,
  ) {
    final inbound = allTraces
        .where((t) => t.targetAgent == run.agentName)
        .toList();
    final outbound = allTraces
        .where((t) => t.sourceAgent == run.agentName)
        .toList();

    return AgentTraceModel(
      agentName: run.agentName,
      order: run.executionOrderIndex,
      inputReceived: run.inputJson,
      outputGenerated: run.outputJson,
      confidenceScore: run.confidenceScore,
      influencedBy: run.influencedBy,
      influencesNext: outbound.map((t) => t.targetAgent).toList(),
      traceSummary: inbound.isNotEmpty ? inbound.first.influenceDescription : null,
      usedGemini: run.usedGemini,
      executionMs: run.executionMs,
    );
  }

  /// Builds the full ordered list of [AgentTraceModel]s from a [SessionResponse].
  static List<AgentTraceModel> fromSession(SessionResponse session) {
    final runs = [...session.agentRuns]
      ..sort((a, b) => a.executionOrderIndex.compareTo(b.executionOrderIndex));
    return runs
        .map((r) => AgentTraceModel.fromAgentRun(r, session.traces))
        .toList();
  }

  // ── Deserialization ────────────────────────────────────────────────────────

  factory AgentTraceModel.fromJson(Map<String, dynamic> j) => AgentTraceModel(
        id: j['id'] as String?,
        agentName: j['agentName'] as String? ?? '',
        order: (j['executionOrderIndex'] as num?)?.toInt() ?? 0,
        inputReceived: j['inputJson'] as String?,
        outputGenerated: j['outputJson'] as String?,
        confidenceScore: (j['confidenceScore'] as num?)?.toDouble() ?? 0.0,
        influencedBy: _parseStringList(j['influencedBy']),
        influencesNext: _parseStringList(j['influencesNext']),
        traceSummary: j['traceSummary'] as String?,
        usedGemini: j['usedGemini'] as bool? ?? false,
        executionMs: (j['executionMs'] as num?)?.toInt() ?? 0,
      );

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'agentName': agentName,
        'executionOrderIndex': order,
        if (inputReceived != null) 'inputJson': inputReceived,
        if (outputGenerated != null) 'outputJson': outputGenerated,
        'confidenceScore': confidenceScore,
        'influencedBy': influencedBy,
        'influencesNext': influencesNext,
        if (traceSummary != null) 'traceSummary': traceSummary,
        'usedGemini': usedGemini,
        'executionMs': executionMs,
      };

  // ── Computed helpers ───────────────────────────────────────────────────────

  /// Short display name: "OrganizationResearch" → "Organization Research".
  String get displayName => agentName
      .replaceAll('Agent', '')
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
      .trim();

  bool get highConfidence => confidenceScore >= 0.8;
  bool get lowConfidence => confidenceScore < 0.5;

  /// True if this agent received output from at least one upstream agent.
  bool get hasInboundInfluence => influencedBy.isNotEmpty;

  /// True if this agent's output reached at least one downstream agent.
  bool get hasOutboundInfluence => influencesNext.isNotEmpty;

  // ── Private helpers ────────────────────────────────────────────────────────

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) return value.split(',');
    return const [];
  }

  @override
  String toString() =>
      'AgentTraceModel($agentName, order: $order, conf: $confidenceScore)';
}
