import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../config/app_config.dart';

/// Wraps stomp_dart_client to deliver per-agent WebSocket progress events
/// from the Spring STOMP broker at /topic/meetings/{id}/progress.
///
/// Usage:
///   final stream = socketService.connect(meetingId);
///   stream.listen((data) { ... });
///   // on dispose:
///   socketService.disconnect();
class PipelineSocketService {
  StompClient? _client;
  StreamController<Map<String, dynamic>>? _controller;

  /// Connect and subscribe; returns a broadcast stream of JSON message maps.
  Stream<Map<String, dynamic>> connect(String meetingId) {
    _controller?.close();
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        onConnect: (StompFrame frame) {
          _client!.subscribe(
            destination: '/topic/meetings/$meetingId/progress',
            callback: (StompFrame frame) {
              final body = frame.body;
              if (body == null || body.isEmpty) return;
              final ctrl = _controller;
              if (ctrl == null || ctrl.isClosed) return;
              try {
                ctrl.add(jsonDecode(body) as Map<String, dynamic>);
              } catch (_) {}
            },
          );
        },
        onWebSocketError: (dynamic error) {
          final ctrl = _controller;
          if (ctrl != null && !ctrl.isClosed) {
            ctrl.addError('WebSocket error: $error');
          }
        },
        onStompError: (StompFrame frame) {
          final ctrl = _controller;
          if (ctrl != null && !ctrl.isClosed) {
            ctrl.addError('STOMP error: ${frame.body ?? "unknown"}');
          }
        },
        onDisconnect: (_) {},
        reconnectDelay: Duration.zero,
      ),
    );

    _client!.activate();
    return _controller!.stream;
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _controller?.close();
    _controller = null;
  }
}
