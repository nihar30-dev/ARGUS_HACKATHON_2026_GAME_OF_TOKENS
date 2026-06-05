import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../config/app_config.dart';
import '../models/pipeline_message.dart';
import '../models/session_response.dart';
import '../services/meeting_repository.dart';
import '../services/pipeline_socket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_header.dart';

// ── Agent definitions ─────────────────────────────────────────────────────────

class _AgentDef {
  final String key;
  final String displayName;
  final bool isLlm;
  final int order;
  const _AgentDef(this.key, this.displayName, this.isLlm, this.order);
}

const List<_AgentDef> _kAgents = [
  _AgentDef('OrganizationResearchAgent', 'Organization Research', true,  1),
  _AgentDef('StakeholderPersonaAgent',   'Stakeholder Persona',   false, 2),
  _AgentDef('EngagementStrategyAgent',   'Engagement Strategy',   true,  3),
  _AgentDef('ObjectionPredictionAgent',  'Objection Prediction',  true,  4),
  _AgentDef('CriticValidatorAgent',      'Critic Validator',      false, 5),
  _AgentDef('StrategyRefinementAgent',   'Strategy Refinement',   true,  6),
  _AgentDef('FinalSynthesisAgent',       'Final Synthesis',       true,  7),
];

// ── Agent state ───────────────────────────────────────────────────────────────

enum _Status { waiting, running, done, failed }

class _AgentState {
  final _Status  status;
  final double?  confidence;
  final int?     executionMs;
  final bool?    usedGemini;
  const _AgentState({
    this.status = _Status.waiting,
    this.confidence,
    this.executionMs,
    this.usedGemini,
  });
  _AgentState copyWith({_Status? status, double? confidence, int? executionMs, bool? usedGemini}) =>
      _AgentState(
        status: status ?? this.status,
        confidence: confidence ?? this.confidence,
        executionMs: executionMs ?? this.executionMs,
        usedGemini: usedGemini ?? this.usedGemini,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PipelineLiveScreen extends StatefulWidget {
  final MeetingStartResponse start;
  const PipelineLiveScreen({super.key, required this.start});

  @override
  State<PipelineLiveScreen> createState() => _PipelineLiveScreenState();
}

class _PipelineLiveScreenState extends State<PipelineLiveScreen> {
  final _socket = PipelineSocketService();
  final Map<String, _AgentState> _states = {};
  bool   _connected = false;
  bool   _done      = false;
  bool   _failed    = false;
  String? _error;
  String? _currentAgentKey;
  int    _completedCount = 0;

  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    for (final a in _kAgents) {
      _states[a.key] = const _AgentState();
    }
    if (AppConfig.useMockData) {
      _runMockSimulation();
    } else {
      _connectAndListen();
    }
  }

  // ── Real WebSocket connection ─────────────────────────────────────────────

  void _connectAndListen() {
    final stream = _socket.connect(widget.start.meetingRequestId);
    setState(() => _connected = true);

    _sub = stream.listen(
      _handleMessage,
      onError: (e) => setState(() {
        _error = e.toString();
        _failed = true;
      }),
    );

    // Fallback: if pipeline completes before WS connects, poll REST after 120s
    _fallbackTimer = Timer(const Duration(seconds: 120), _fallbackFetch);
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'AGENT_START':
        final name = data['agentName'] as String? ?? '';
        setState(() {
          _currentAgentKey = name;
          _states[name] = _states[name]!.copyWith(status: _Status.running);
        });
        break;

      case 'AGENT_COMPLETE':
        final name = data['agentName'] as String? ?? '';
        setState(() {
          _states[name] = _AgentState(
            status: _Status.done,
            confidence: (data['confidenceScore'] as num?)?.toDouble(),
            executionMs: (data['executionMs'] as num?)?.toInt(),
            usedGemini: data['usedGemini'] as bool?,
          );
          if (_currentAgentKey == name) _currentAgentKey = null;
          _completedCount = _states.values.where((s) => s.status == _Status.done).length;
        });
        break;

      case 'PIPELINE_COMPLETE':
        _fallbackTimer?.cancel();
        final session = _buildSession(data);
        setState(() {
          _done = true;
          _completedCount = _kAgents.length;
          for (final a in _kAgents) {
            if (_states[a.key]!.status != _Status.done) {
              _states[a.key] = _states[a.key]!.copyWith(status: _Status.done);
            }
          }
        });
        _navigateToDashboard(session);
        break;

      case 'PIPELINE_FAILED':
        _fallbackTimer?.cancel();
        setState(() {
          _failed = true;
          _error = data['errorMessage'] as String? ?? 'Pipeline failed';
        });
        break;
    }
  }

  SessionResponse _buildSession(Map<String, dynamic> data) {
    // Inject status/organizationName fields so SessionResponse.fromJson works
    final merged = Map<String, dynamic>.from(data);
    merged['status'] = 'COMPLETED';
    return SessionResponse.fromJson(merged);
  }

  Future<void> _fallbackFetch() async {
    if (_done || _failed || !mounted) return;
    try {
      final repo = context.read<MeetingRepository>();
      final session = await repo.getMeeting(widget.start.meetingRequestId);
      if (!mounted) return;
      if (session.status == 'COMPLETED') {
        setState(() { _done = true; _completedCount = _kAgents.length; });
        _navigateToDashboard(session);
      } else if (session.status == 'FAILED') {
        setState(() { _failed = true; _error = 'Pipeline failed on server'; });
      } else {
        // Still running — check again in 15s
        _fallbackTimer = Timer(const Duration(seconds: 15), _fallbackFetch);
      }
    } catch (_) {}
  }

  void _navigateToDashboard(SessionResponse session) {
    context.read<MeetingRepository>().addToRecent(session);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.trace,
        (route) => route.settings.name == Routes.home,
        arguments: session,
      );
    });
  }

  // ── Mock simulation ───────────────────────────────────────────────────────

  void _runMockSimulation() {
    setState(() => _connected = true);
    int step = 0;
    Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (step >= _kAgents.length) { timer.cancel(); return; }
      final agent = _kAgents[step];
      setState(() {
        _currentAgentKey = agent.key;
        _states[agent.key] = const _AgentState(status: _Status.running);
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _states[agent.key] = _AgentState(
            status: _Status.done,
            confidence: 0.80 + (step * 0.02),
            executionMs: 500 + step * 300,
            usedGemini: agent.isLlm,
          );
          _currentAgentKey = null;
          _completedCount = _states.values.where((s) => s.status == _Status.done).length;
        });
      });
      step++;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fallbackTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = _kAgents.isEmpty ? 0.0 : _completedCount / _kAgents.length;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preparing Meeting Strategy',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.start.organizationName,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
        automaticallyImplyLeading: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          // Progress bar
          _ProgressHeader(progress: progress, completed: _completedCount, total: _kAgents.length),

          // Status message
          if (!_done && !_failed)
            _CurrentAgentBanner(agentKey: _currentAgentKey, connected: _connected),

          if (_failed)
            _ErrorBanner(error: _error ?? 'Pipeline failed', onRetry: _fallbackFetch),

          if (_done)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: AppColors.successLight,
              child: const Row(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('Pipeline complete — opening trace view...',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),

          // Agent list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _kAgents.length,
              itemBuilder: (ctx, i) {
                final def   = _kAgents[i];
                final state = _states[def.key]!;
                return _AgentRow(def: def, state: state, cs: cs);
              },
            ),
          ),

          // Bottom action — only shown when done or failed
          if (_done || _failed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Form'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;
  const _ProgressHeader({required this.progress, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Multi-Agent Pipeline',
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)),
            Text('$completed / $total agents',
                style: TextStyle(fontSize: 13,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppSpacing.roundedPill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _CurrentAgentBanner extends StatelessWidget {
  final String? agentKey;
  final bool connected;
  const _CurrentAgentBanner({this.agentKey, required this.connected});

  @override
  Widget build(BuildContext context) {
    final text = !connected
        ? 'Connecting to pipeline...'
        : agentKey == null
            ? 'Waiting for pipeline to start...'
            : 'Running: ${_label(agentKey!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppColors.brandSubtle,
      child: Row(children: [
        const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: AppColors.brand, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  String _label(String key) {
    try {
      return _kAgents.firstWhere((a) => a.key == key).displayName;
    } catch (_) { return key; }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppColors.dangerLight,
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(error,
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry', style: TextStyle(color: AppColors.danger)),
        ),
      ]),
    );
  }
}

class _AgentRow extends StatelessWidget {
  final _AgentDef def;
  final _AgentState state;
  final ColorScheme cs;
  const _AgentRow({required this.def, required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isRunning = state.status == _Status.running;
    final isDone    = state.status == _Status.done;
    final isFailed  = state.status == _Status.failed;
    final isWaiting = state.status == _Status.waiting;

    final Color rowColor = isDone
        ? AppColors.success
        : isRunning
            ? AppColors.brand
            : isFailed
                ? AppColors.danger
                : AppColors.textMuted;

    final bgColor = isDone
        ? AppColors.successLight
        : isRunning
            ? AppColors.brandSubtle
            : cs.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isRunning ? AppColors.brand : isDone ? AppColors.success.withValues(alpha: 0.4) : AppColors.outline,
          width: isRunning ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          // Status icon
          SizedBox(
            width: 24, height: 24,
            child: isRunning
                ? CircularProgressIndicator(strokeWidth: 2.5, color: rowColor)
                : isDone
                    ? Icon(Icons.check_circle_rounded, color: rowColor, size: 22)
                    : isFailed
                        ? Icon(Icons.error_outline, color: rowColor, size: 22)
                        : Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.outline, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text('${def.order}',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: rowColor)),
                          ),
          ),
          const SizedBox(width: 12),

          // Name + type
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(def.displayName,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRunning || isDone ? FontWeight.w700 : FontWeight.w500,
                      color: isDone || isRunning ? AppColors.textPrimary : AppColors.textMuted)),
              if (isRunning)
                const Text('Running...', style: TextStyle(fontSize: 11, color: AppColors.brand)),
              if (isWaiting)
                Text(def.isLlm ? 'Gemini AI' : 'Rule-based',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ),

          // Right side: badges
          if (isDone) ...[
            if (state.confidence != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.forConfidenceSurface(state.confidence!),
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  '${(state.confidence! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.forConfidence(state.confidence!)),
                ),
              ),
            const SizedBox(width: 6),
            if (state.executionMs != null)
              Text('${state.executionMs}ms',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (state.usedGemini ?? def.isLlm) ? AppColors.geminiSurface : AppColors.ruleBasedSurface,
                borderRadius: AppSpacing.roundedPill,
              ),
              child: Text(
                (state.usedGemini ?? def.isLlm) ? 'AI' : 'Rule',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: (state.usedGemini ?? def.isLlm) ? AppColors.gemini : AppColors.ruleBased),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
