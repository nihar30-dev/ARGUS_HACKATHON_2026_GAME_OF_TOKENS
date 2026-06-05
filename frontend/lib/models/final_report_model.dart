import 'dart:convert';
import 'session_response.dart';

// ── Sub-models ────────────────────────────────────────────────────────────────

/// One phase in the recommended meeting conversation flow.
///
/// JSON shape (inside conversationFlowJson array):
///   { "phase": "...", "duration": "5 min", "approach": "..." }
class ConversationPhase {
  final String phase;
  final String? duration;
  final String? approach;

  const ConversationPhase({
    required this.phase,
    this.duration,
    this.approach,
  });

  factory ConversationPhase.fromJson(Map<String, dynamic> j) =>
      ConversationPhase(
        phase: j['phase'] as String? ?? '',
        duration: j['duration'] as String?,
        approach: j['approach'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'phase': phase,
        if (duration != null) 'duration': duration,
        if (approach != null) 'approach': approach,
      };

  @override
  String toString() => 'ConversationPhase($phase, $duration)';
}

// ─────────────────────────────────────────────────────────────────────────────

/// A predicted stakeholder objection and the recommended response.
///
/// JSON shape (inside objectionResponsesJson array):
///   { "objection": "...", "response": "..." }
class ObjectionResponse {
  final String objection;
  final String response;

  const ObjectionResponse({
    required this.objection,
    required this.response,
  });

  factory ObjectionResponse.fromJson(Map<String, dynamic> j) =>
      ObjectionResponse(
        objection: j['objection'] as String? ?? '',
        response: j['response'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'objection': objection,
        'response': response,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Recommended behaviors for the meeting.
///
/// JSON shape (inside doAndDontJson, when present):
///   { "dos": ["...", ...], "donts": ["...", ...] }
///
/// Note: this field is not yet emitted by the backend — it defaults to empty
/// lists so screens can render it safely if/when the backend adds it.
class DoAndDont {
  final List<String> dos;
  final List<String> donts;

  const DoAndDont({
    this.dos = const [],
    this.donts = const [],
  });

  const DoAndDont.empty()
      : dos = const [],
        donts = const [];

  factory DoAndDont.fromJson(Map<String, dynamic> j) => DoAndDont(
        dos: _parseList(j['dos']),
        donts: _parseList(j['donts']),
      );

  Map<String, dynamic> toJson() => {
        'dos': dos,
        'donts': donts,
      };

  bool get isEmpty => dos.isEmpty && donts.isEmpty;

  static List<String> _parseList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}

// ── Main model ────────────────────────────────────────────────────────────────

/// Rich final report model with all JSON sub-fields pre-parsed into typed lists.
///
/// The backend stores nested data as JSON strings inside TEXT columns
/// (conversationFlowJson, questionsJson, etc.). This model parses those
/// strings on construction so the UI never calls jsonDecode directly.
///
/// JSON key mapping:
///   readinessScore   ↔  "overallConfidence"
///   questionsToAsk   ↔  "questionsJson"        (array of strings)
///   conversationFlow ↔  "conversationFlowJson"  (array of ConversationPhase)
///   objections       ↔  "objectionResponsesJson" (array of ObjectionResponse)
///   nextSteps        ↔  "nextStepsJson"          (array of strings)
///   doAndDont        ↔  "doAndDontJson"          (not yet in backend — safe null)
///   meetingObjective ↔  not in FinalReportDTO — pass in from MeetingRequest
class FinalReportModel {
  final String? id;
  final String? sessionId;

  final String? executiveBrief;

  /// Not stored in FinalReportDTO — populate from the parent MeetingRequest
  /// when available (e.g., from SessionResponse).
  final String? meetingObjective;

  final List<ConversationPhase> conversationFlow;
  final List<String> questionsToAsk;
  final List<ObjectionResponse> objectionsAndResponses;

  /// Defaults to empty — backend does not emit this field yet.
  final DoAndDont doAndDont;

  final List<String> nextSteps;

  /// Maps to "overallConfidence" in the backend (0.0–1.0).
  final double readinessScore;

  final String? generatedAt;

  const FinalReportModel({
    this.id,
    this.sessionId,
    this.executiveBrief,
    this.meetingObjective,
    this.conversationFlow = const [],
    this.questionsToAsk = const [],
    this.objectionsAndResponses = const [],
    this.doAndDont = const DoAndDont.empty(),
    this.nextSteps = const [],
    this.readinessScore = 0.0,
    this.generatedAt,
  });

  // ── Factory: build from existing FinalReport model ────────────────────────

  /// Upgrades a [FinalReport] (from session_response.dart) into a
  /// [FinalReportModel] with all sub-fields parsed.
  factory FinalReportModel.fromDto(FinalReport dto, {String? meetingObjective}) =>
      FinalReportModel.fromJson(
        {
          'executiveBrief': dto.executiveBrief,
          'conversationFlowJson': dto.conversationFlowJson,
          'questionsJson': dto.questionsJson,
          'objectionResponsesJson': dto.objectionResponsesJson,
          'nextStepsJson': dto.nextStepsJson,
          'overallConfidence': dto.overallConfidence,
        },
        meetingObjective: meetingObjective,
      );

  // ── Deserialization ────────────────────────────────────────────────────────

  factory FinalReportModel.fromJson(
    Map<String, dynamic> j, {
    String? meetingObjective,
  }) =>
      FinalReportModel(
        id: j['id'] as String?,
        sessionId: j['sessionId'] as String?,
        executiveBrief: j['executiveBrief'] as String?,
        meetingObjective: meetingObjective ?? j['meetingObjective'] as String?,
        conversationFlow: _parseJsonArray(
          j['conversationFlowJson'],
          ConversationPhase.fromJson,
        ),
        questionsToAsk: _parseStringArray(j['questionsJson']),
        objectionsAndResponses: _parseJsonArray(
          j['objectionResponsesJson'],
          ObjectionResponse.fromJson,
        ),
        doAndDont: _parseDoAndDont(j['doAndDontJson']),
        nextSteps: _parseStringArray(j['nextStepsJson']),
        readinessScore: (j['overallConfidence'] as num?)?.toDouble() ?? 0.0,
        generatedAt: j['generatedAt'] as String?,
      );

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (sessionId != null) 'sessionId': sessionId,
        if (executiveBrief != null) 'executiveBrief': executiveBrief,
        if (meetingObjective != null) 'meetingObjective': meetingObjective,
        'conversationFlowJson': jsonEncode(conversationFlow.map((e) => e.toJson()).toList()),
        'questionsJson': jsonEncode(questionsToAsk),
        'objectionResponsesJson': jsonEncode(objectionsAndResponses.map((e) => e.toJson()).toList()),
        'doAndDontJson': jsonEncode(doAndDont.toJson()),
        'nextStepsJson': jsonEncode(nextSteps),
        'overallConfidence': readinessScore,
        if (generatedAt != null) 'generatedAt': generatedAt,
      };

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get hasConversationFlow => conversationFlow.isNotEmpty;
  bool get hasObjections => objectionsAndResponses.isNotEmpty;
  bool get hasDoAndDont => !doAndDont.isEmpty;
  bool get hasNextSteps => nextSteps.isNotEmpty;

  bool get highReadiness => readinessScore >= 0.8;
  bool get lowReadiness => readinessScore < 0.5;

  String get readinessLabel {
    if (readinessScore >= 0.8) return 'High';
    if (readinessScore >= 0.5) return 'Medium';
    return 'Low';
  }

  // ── Private parsing helpers ────────────────────────────────────────────────

  static List<T> _parseJsonArray<T>(
    dynamic rawJsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (rawJsonString == null) return const [];
    try {
      final decoded = rawJsonString is String
          ? jsonDecode(rawJsonString)
          : rawJsonString;
      return (decoded as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<String> _parseStringArray(dynamic rawJsonString) {
    if (rawJsonString == null) return const [];
    try {
      final decoded = rawJsonString is String
          ? jsonDecode(rawJsonString)
          : rawJsonString;
      return (decoded as List<dynamic>).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  static DoAndDont _parseDoAndDont(dynamic rawJsonString) {
    if (rawJsonString == null) return const DoAndDont.empty();
    try {
      final decoded = rawJsonString is String
          ? jsonDecode(rawJsonString)
          : rawJsonString;
      return DoAndDont.fromJson(decoded as Map<String, dynamic>);
    } catch (_) {
      return const DoAndDont.empty();
    }
  }

  @override
  String toString() =>
      'FinalReportModel(readiness: $readinessScore, '
      'phases: ${conversationFlow.length}, '
      'questions: ${questionsToAsk.length})';
}
