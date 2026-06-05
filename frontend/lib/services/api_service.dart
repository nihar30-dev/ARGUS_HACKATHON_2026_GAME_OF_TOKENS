import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/pipeline_message.dart';
import '../models/session_response.dart';

// Timeout and base URL are configured in lib/config/app_config.dart.
// Do not hardcode values here — edit AppConfig instead.

/// HTTP client for the MeetWise Spring Boot backend.
///
/// All methods throw [ApiException] on failure — never a raw SocketException,
/// TimeoutException, or FormatException — so callers can write a single
/// `catch (e)` and show `e.toString()` without worrying about crash types.
class ApiService {
  // Base URL defaults to AppConfig.backendBaseUrl.
  // Override via the constructor only in tests.
  final String baseUrl;

  /// Optional callback that returns the current Bearer token.
  /// Called on every request so token changes propagate automatically.
  final String? Function()? _getToken;

  ApiService({String? baseUrl, String? Function()? tokenProvider})
      : baseUrl = baseUrl ?? AppConfig.backendBaseUrl,
        _getToken = tokenProvider;

  // ── Endpoints ──────────────────────────────────────────────────────────────

  /// POST /api/meetings — starts async pipeline; returns meetingRequestId immediately.
  Future<MeetingStartResponse> startMeeting({
    required String organizationName,
    required String meetingObjective,
    required String offeringDescription,
    required String stakeholderRole,
  }) =>
      _execute('POST /meetings (start)', () async {
        final res = await http
            .post(
              Uri.parse('$baseUrl/meetings'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'organizationName': organizationName,
                'meetingObjective': meetingObjective,
                'offeringDescription': offeringDescription,
                'stakeholderRole': stakeholderRole,
              }),
            )
            .timeout(AppConfig.apiTimeout);
        _assertSuccess(res, 'POST /meetings');
        return MeetingStartResponse.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      });

  /// POST /api/meetings/demo — async demo pipeline; returns meetingRequestId immediately.
  Future<MeetingStartResponse> startDemo() =>
      _execute('POST /meetings/demo (start)', () async {
        final res = await http
            .post(Uri.parse('$baseUrl/meetings/demo'), headers: _jsonHeaders)
            .timeout(AppConfig.apiTimeout);
        _assertSuccess(res, 'POST /meetings/demo');
        return MeetingStartResponse.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      });

  /// POST /api/meetings — runs the full 6-agent pipeline synchronously.
  /// Keeps named parameters for backward compatibility with [MeetingInputScreen].
  Future<SessionResponse> createMeeting({
    required String organizationName,
    required String meetingObjective,
    required String offeringDescription,
    required String stakeholderRole,
  }) =>
      _execute('POST /meetings', () async {
        final res = await http
            .post(
              Uri.parse('$baseUrl/meetings'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'organizationName': organizationName,
                'meetingObjective': meetingObjective,
                'offeringDescription': offeringDescription,
                'stakeholderRole': stakeholderRole,
              }),
            )
            .timeout(AppConfig.apiTimeout);
        return _parseSession(res, 'POST /meetings');
      });

  /// POST /api/meetings/{id}/run — triggers pipeline on an existing request.
  Future<SessionResponse> runMeeting(String id) =>
      _execute('POST /meetings/$id/run', () async {
        final res = await http
            .post(
              Uri.parse('$baseUrl/meetings/$id/run'),
              headers: _jsonHeaders,
            )
            .timeout(AppConfig.apiTimeout);
        return _parseSession(res, 'POST /meetings/$id/run');
      });

  /// POST /api/meetings/demo — Apollo Hospitals demo; works without Gemini.
  Future<SessionResponse> runDemo() =>
      _execute('POST /meetings/demo', () async {
        final res = await http
            .post(
              Uri.parse('$baseUrl/meetings/demo'),
              headers: _jsonHeaders,
            )
            .timeout(AppConfig.apiTimeout);
        return _parseSession(res, 'POST /meetings/demo');
      });

  /// GET /api/meetings/{sessionId} — full session with runs, traces, report.
  Future<SessionResponse> getSession(String sessionId) =>
      _execute('GET /meetings/$sessionId', () async {
        final res = await http
            .get(Uri.parse('$baseUrl/meetings/$sessionId'))
            .timeout(AppConfig.apiTimeout);
        return _parseSession(res, 'GET /meetings/$sessionId');
      });

  /// GET /api/meetings/{sessionId}/traces — agent influence links only.
  Future<List<AgentTrace>> getTraces(String sessionId) =>
      _execute('GET /meetings/$sessionId/traces', () async {
        final res = await http
            .get(Uri.parse('$baseUrl/meetings/$sessionId/traces'))
            .timeout(AppConfig.apiTimeout);
        _assertSuccess(res, 'GET /meetings/$sessionId/traces');
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// GET /api/meetings/{sessionId}/report — final synthesis report, or null
  /// if the pipeline has not completed yet (404 → null, not an error).
  Future<FinalReport?> getReport(String sessionId) =>
      _execute('GET /meetings/$sessionId/report', () async {
        final res = await http
            .get(Uri.parse('$baseUrl/meetings/$sessionId/report'))
            .timeout(AppConfig.apiTimeout);
        if (res.statusCode == 404) {
          _log('GET /meetings/$sessionId/report → 404 (not ready yet)');
          return null;
        }
        _assertSuccess(res, 'GET /meetings/$sessionId/report');
        return FinalReport.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      });

  // ── Private helpers ────────────────────────────────────────────────────────

  Map<String, String> get _jsonHeaders {
    final token = _getToken?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  SessionResponse _parseSession(http.Response res, String label) {
    _assertSuccess(res, label);
    return SessionResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  void _assertSuccess(http.Response res, String label) {
    _log('$label → ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _log('$label error body: ${res.body}');
      throw ApiException(
        'Server returned ${res.statusCode}',
        statusCode: res.statusCode,
        body: res.body,
      );
    }
  }

  /// Runs [fn] and converts low-level network/format exceptions to [ApiException].
  Future<T> _execute<T>(String label, Future<T> Function() fn) async {
    _log('→ $label');
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      _log('$label timed out after ${AppConfig.apiTimeout.inSeconds}s');
      throw ApiException(
        'Request timed out after ${AppConfig.apiTimeout.inSeconds}s. '
        'The pipeline may still be running — check AppConfig.apiTimeout if this happens frequently.',
        label: label,
      );
    } on SocketException catch (e) {
      _log('$label connection error: $e');
      throw ApiException(
        'Cannot reach server — is the backend running on ${Uri.parse(baseUrl).host}?',
        label: label,
      );
    } on FormatException catch (e) {
      _log('$label bad JSON: $e');
      throw ApiException('Server returned unexpected response format', label: label);
    } catch (e) {
      _log('$label unexpected error: $e');
      throw ApiException('Unexpected error: $e', label: label);
    }
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[ApiService] $message');
  }
}

// ── ApiException ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  final String? label;

  const ApiException(
    this.message, {
    this.statusCode,
    this.body,
    this.label,
  });

  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;
  bool get isServerError => (statusCode ?? 0) >= 500;

  /// True when the exception is a timeout or connection failure (no HTTP status).
  bool get isNetworkError => statusCode == null;

  @override
  String toString() {
    if (isNetworkError) return message;
    return 'Error $statusCode: $message';
  }
}
