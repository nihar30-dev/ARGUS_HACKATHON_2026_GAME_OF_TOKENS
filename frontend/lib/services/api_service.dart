import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/session_response.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8080/api';

  Future<SessionResponse> createMeeting({
    required String organizationName,
    required String meetingObjective,
    required String offeringDescription,
    required String stakeholderRole,
  }) async {
    final body = jsonEncode({
      'organizationName': organizationName,
      'meetingObjective': meetingObjective,
      'offeringDescription': offeringDescription,
      'stakeholderRole': stakeholderRole,
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/meetings'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return _parseSession(response);
  }

  Future<SessionResponse> runDemo() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/meetings/demo'),
      headers: {'Content-Type': 'application/json'},
    );
    return _parseSession(response);
  }

  Future<SessionResponse> getSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/meetings/$sessionId'),
    );
    return _parseSession(response);
  }

  SessionResponse _parseSession(http.Response response) {
    if (response.statusCode != 200) {
      debugPrint('API error ${response.statusCode}: ${response.body}');
      throw ApiException('Request failed: ${response.statusCode}', response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SessionResponse.fromJson(json);
  }
}

class ApiException implements Exception {
  final String message;
  final String? body;
  const ApiException(this.message, [this.body]);

  @override
  String toString() => 'ApiException: $message';
}
