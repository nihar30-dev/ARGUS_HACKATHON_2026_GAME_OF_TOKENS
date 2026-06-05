class AgentRun {
  final String agentName;
  final int executionOrderIndex;
  final String? inputJson;
  final String outputJson;
  final double confidenceScore;
  final List<String> influencedBy;
  final bool usedGemini;
  final int executionMs;

  AgentRun({
    required this.agentName,
    required this.executionOrderIndex,
    this.inputJson,
    required this.outputJson,
    required this.confidenceScore,
    required this.influencedBy,
    required this.usedGemini,
    required this.executionMs,
  });

  factory AgentRun.fromJson(Map<String, dynamic> j) => AgentRun(
        agentName: j['agentName'] as String,
        executionOrderIndex: j['executionOrderIndex'] as int,
        inputJson: j['inputJson'] as String?,
        outputJson: j['outputJson'] as String,
        confidenceScore: (j['confidenceScore'] as num).toDouble(),
        influencedBy: List<String>.from(j['influencedBy'] ?? []),
        usedGemini: j['usedGemini'] as bool? ?? false,
        executionMs: (j['executionMs'] as num?)?.toInt() ?? 0,
      );

  String get displayName => agentName.replaceAll('Agent', '').replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => ' ${m.group(0)}',
      ).trim();
}

class AgentTrace {
  final String sourceAgent;
  final String targetAgent;
  final String? inputSummary;
  final String? outputSummary;
  final String? influenceDescription;

  AgentTrace({
    required this.sourceAgent,
    required this.targetAgent,
    this.inputSummary,
    this.outputSummary,
    this.influenceDescription,
  });

  factory AgentTrace.fromJson(Map<String, dynamic> j) => AgentTrace(
        sourceAgent: j['sourceAgent'] as String,
        targetAgent: j['targetAgent'] as String,
        inputSummary: j['inputSummary'] as String?,
        outputSummary: j['outputSummary'] as String?,
        influenceDescription: j['influenceDescription'] as String?,
      );
}

class FinalReport {
  final String? executiveBrief;
  final String? conversationFlowJson;
  final String? questionsJson;
  final String? objectionResponsesJson;
  final String? nextStepsJson;
  final double overallConfidence;

  FinalReport({
    this.executiveBrief,
    this.conversationFlowJson,
    this.questionsJson,
    this.objectionResponsesJson,
    this.nextStepsJson,
    required this.overallConfidence,
  });

  factory FinalReport.fromJson(Map<String, dynamic> j) => FinalReport(
        executiveBrief: j['executiveBrief'] as String?,
        conversationFlowJson: j['conversationFlowJson'] as String?,
        questionsJson: j['questionsJson'] as String?,
        objectionResponsesJson: j['objectionResponsesJson'] as String?,
        nextStepsJson: j['nextStepsJson'] as String?,
        overallConfidence: (j['overallConfidence'] as num?)?.toDouble() ?? 0.0,
      );
}

class SessionResponse {
  final String sessionId;
  final String organizationName;
  final String status;
  final List<AgentRun> agentRuns;
  final List<AgentTrace> traces;
  final FinalReport? finalReport;

  SessionResponse({
    required this.sessionId,
    required this.organizationName,
    required this.status,
    required this.agentRuns,
    required this.traces,
    this.finalReport,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> j) => SessionResponse(
        sessionId: j['sessionId'] as String,
        organizationName: j['organizationName'] as String,
        status: j['status'] as String,
        agentRuns: (j['agentRuns'] as List<dynamic>? ?? [])
            .map((e) => AgentRun.fromJson(e as Map<String, dynamic>))
            .toList(),
        traces: (j['traces'] as List<dynamic>? ?? [])
            .map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
            .toList(),
        finalReport: j['finalReport'] != null
            ? FinalReport.fromJson(j['finalReport'] as Map<String, dynamic>)
            : null,
      );
}
