// Re-export ApiException so screens only need to import this file.
// Do not import api_service.dart directly in screens.
export 'api_service.dart' show ApiException;

import '../config/app_config.dart';
import '../models/session_response.dart';
import 'api_service.dart';
import 'mock_meeting_service.dart';

/// Single data-access point for all meeting operations.
///
/// ── Switching between mock and live backend ──────────────────────────────────
///
/// Edit [AppConfig] in `lib/config/app_config.dart` — that file is the ONLY
/// place you need to change:
///
///   static const bool useMockData = false;          // enable real backend
///   static const String backendBaseUrl = '...';    // set your server URL
///
/// ────────────────────────────────────────────────────────────────────────────
///
/// All screens call this class exclusively. Neither [ApiService] nor
/// [MockMeetingService] is imported anywhere outside this file.
class MeetingRepository {
  // Read from AppConfig — do NOT add a local useMockData constant here.
  // Change the flag in lib/config/app_config.dart.
  static bool get useMockData => AppConfig.useMockData;

  final ApiService _api;
  final MockMeetingService _mock;
  final List<SessionResponse> _recentMeetings = [];

  MeetingRepository({ApiService? api, MockMeetingService? mock})
      : _api = api ?? ApiService(),
        _mock = mock ?? MockMeetingService();

  List<SessionResponse> get recentMeetings => List.unmodifiable(_recentMeetings);

  // ── Methods ────────────────────────────────────────────────────────────────

  /// POST /api/meetings — runs the full 6-agent pipeline.
  Future<SessionResponse> createMeeting({
    required String organizationName,
    required String meetingObjective,
    required String offeringDescription,
    required String stakeholderRole,
  }) async {
    final SessionResponse session;
    if (useMockData) {
      session = await _mock.runDemo(simulatedDelay: AppConfig.mockDelay);
    } else {
      session = await _api.createMeeting(
        organizationName: organizationName,
        meetingObjective: meetingObjective,
        offeringDescription: offeringDescription,
        stakeholderRole: stakeholderRole,
      );
    }
    _recentMeetings.insert(0, session);
    return session;
  }

  /// Runs the Apollo Hospitals demo.
  Future<SessionResponse> runDemo() async {
    final SessionResponse session;
    if (useMockData) {
      session = await _mock.runDemo(simulatedDelay: AppConfig.mockDelay);
    } else {
      session = await _api.runDemo();
    }
    _recentMeetings.insert(0, session);
    return session;
  }

  /// POST /api/meetings/{id}/run — triggers the pipeline on an existing request.
  Future<SessionResponse> runMeeting(String sessionId) async {
    final SessionResponse session;
    if (useMockData) {
      session = await _mock.getSession(sessionId);
    } else {
      session = await _api.runMeeting(sessionId);
    }
    _updateRecent(session);
    return session;
  }

  /// GET /api/meetings/{id} — full session with runs, traces, and report.
  Future<SessionResponse> getMeeting(String sessionId) async {
    final SessionResponse session;
    if (useMockData) {
      session = await _mock.getSession(sessionId);
    } else {
      session = await _api.getSession(sessionId);
    }
    _updateRecent(session);
    return session;
  }

  /// GET /api/meetings/{id}/traces — agent influence links only.
  Future<List<AgentTrace>> getTrace(String sessionId) async {
    if (useMockData) {
      final session = await _mock.getSession(sessionId);
      return session.traces;
    }
    return _api.getTraces(sessionId);
  }

  /// GET /api/meetings/{id}/report — final synthesis report, or null if not ready.
  Future<FinalReport?> getReport(String sessionId) async {
    if (useMockData) {
      final session = await _mock.getSession(sessionId);
      return session.finalReport;
    }
    return _api.getReport(sessionId);
  }

  void _updateRecent(SessionResponse session) {
    final idx = _recentMeetings.indexWhere((s) => s.sessionId == session.sessionId);
    if (idx != -1) {
      _recentMeetings[idx] = session;
    } else {
      _recentMeetings.insert(0, session);
    }
  }
}
