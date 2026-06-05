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
        agentName: j['agentName'] as String? ?? '',
        executionOrderIndex: (j['executionOrder'] as num?)?.toInt() ?? 0,
        inputJson: j['inputPayload'] as String?,
        outputJson: j['outputPayload'] as String? ?? '{}',
        confidenceScore: (j['confidenceScore'] as num?)?.toDouble() ?? 0.0,
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
        sourceAgent: j['sourceAgent'] as String? ?? '',
        targetAgent: j['targetAgent'] as String? ?? '',
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
  final String? doAndDontJson;
  final String? nextStepsJson;
  final double overallConfidence;

  FinalReport({
    this.executiveBrief,
    this.conversationFlowJson,
    this.questionsJson,
    this.objectionResponsesJson,
    this.doAndDontJson,
    this.nextStepsJson,
    required this.overallConfidence,
  });

  factory FinalReport.fromJson(Map<String, dynamic> j) => FinalReport(
        executiveBrief: j['executiveBrief'] as String?,
        conversationFlowJson: j['conversationFlowJson'] as String?,
        questionsJson: j['questionsJson'] as String?,
        objectionResponsesJson: j['objectionResponsesJson'] as String?,
        doAndDontJson: null,
        nextStepsJson: j['nextStepsJson'] as String?,
        overallConfidence: (j['overallConfidence'] as num?)?.toDouble() ?? 0.0,
      );
}

class SessionResponse {
  final String sessionId;
  final String organizationName;
  final String? meetingObjective;
  final String? stakeholderRole;
  final String status;
  final List<AgentRun> agentRuns;
  final List<AgentTrace> traces;
  final FinalReport? finalReport;

  SessionResponse({
    required this.sessionId,
    required this.organizationName,
    this.meetingObjective,
    this.stakeholderRole,
    required this.status,
    required this.agentRuns,
    required this.traces,
    this.finalReport,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> j) => SessionResponse(
        sessionId: (j['meetingRequestId'] ?? j['sessionId'] ?? '').toString(),
        organizationName: j['organizationName'] as String? ?? '',
        meetingObjective: j['meetingObjective'] as String?,
        stakeholderRole: j['stakeholderRole'] as String?,
        // PIPELINE_COMPLETE WS message uses pipelineStatus; REST uses status
        status: j['status'] as String? ?? j['pipelineStatus'] as String? ?? 'UNKNOWN',
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
