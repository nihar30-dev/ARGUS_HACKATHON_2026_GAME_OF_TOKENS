import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
import '../models/agent_trace_model.dart';
import '../models/session_response.dart';
import '../services/meeting_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_card.dart';
import '../widgets/app_header.dart';
import '../widgets/error_view.dart';
import '../widgets/trace_workflow_widget.dart';

// ── Agent Metadata ─────────────────────────────────────────────────────────────

const Map<String, String> _kShortNames = {
  'OrganizationResearchAgent': 'Research',
  'StakeholderPersonaAgent':   'Persona',
  'EngagementStrategyAgent':   'Strategy',
  'ObjectionPredictionAgent':  'Objection',
  'CriticValidatorAgent':      'Critic',
  'StrategyRefinementAgent':   'Refinement',
  'FinalSynthesisAgent':       'Synthesis',
};

const List<String> _kAgentNames = [
  'OrganizationResearchAgent',
  'StakeholderPersonaAgent',
  'EngagementStrategyAgent',
  'ObjectionPredictionAgent',
  'CriticValidatorAgent',
  'StrategyRefinementAgent',
  'FinalSynthesisAgent',
];

const List<String> _kDisplayNames = [
  'Organization Research',
  'Stakeholder Persona',
  'Engagement Strategy',
  'Objection Prediction',
  'Critic Validator',
  'Strategy Refinement',
  'Final Synthesis',
];

const List<IconData> _kIcons = [
  Icons.search_outlined,
  Icons.person_outlined,
  Icons.lightbulb_outline,
  Icons.warning_amber_outlined,
  Icons.fact_check_outlined,
  Icons.tune_outlined,
  Icons.summarize_outlined,
];

// Rule-based agents (0-indexed): 1=Persona, 4=Critic, 5=Refinement
const Set<int> _kRuleBasedIndices = {1, 4, 5};

// Keys always stripped from parsed output — rendered elsewhere in the card
const Set<String> _kSkipOutputKeys = {
  'agent', 'agentName', 'influencedBy', 'confidenceScore',
  'usedGemini', 'executionMs', 'executionOrderIndex',
};

// ── Screen ─────────────────────────────────────────────────────────────────────

class AgentTraceScreen extends StatefulWidget {
  final SessionResponse session;
  const AgentTraceScreen({super.key, required this.session});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  late SessionResponse _session;
  late List<AgentTraceModel> _models;
  Timer? _pollTimer;
  final Set<String> _expanded = {};
  String? _pollError;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _models = AgentTraceModel.fromSession(_session);
    _autoExpand();
    if (_session.status == 'RUNNING') _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _autoExpand() {
    if (_session.status == 'COMPLETED') {
      _expanded.addAll(['CriticValidatorAgent', 'FinalSynthesisAgent']);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final repo = context.read<MeetingRepository>();
        final updated = await repo.getMeeting(_session.sessionId);
        if (!mounted) return;
        setState(() {
          _session = updated;
          _models = AgentTraceModel.fromSession(_session);
          _pollError = null;
          if (_session.status == 'COMPLETED') {
            _pollTimer?.cancel();
            _autoExpand();
          }
        });
      } catch (_) {
        if (mounted) setState(() => _pollError = 'Connection lost — retrying…');
      }
    });
  }

  void _toggle(String name) => setState(() =>
      _expanded.contains(name) ? _expanded.remove(name) : _expanded.add(name));

  void _expandAll() =>
      setState(() => _expanded.addAll(_models.map((m) => m.agentName)));
  void _collapseAll() => setState(() => _expanded.clear());

  @override
  Widget build(BuildContext context) {
    if (_models.isEmpty && _session.status != 'RUNNING') {
      return Scaffold(
        appBar: _appBar(),
        body: ErrorView(
          compact: false,
          isError: false,
          icon: Icons.account_tree_outlined,
          title: 'No Pipeline Traces',
          message: 'No agent execution data exists for this session.',
          onRetry: () => Navigator.pop(context),
          retryLabel: 'Go Back',
        ),
      );
    }

    return Scaffold(
      appBar: _appBar(),
      body: Column(
        children: [
          if (_pollError != null)
            Container(
              color: AppColors.danger,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 6, horizontal: AppSpacing.md),
              alignment: Alignment.center,
              child: Text(_pollError!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          _StatusBar(
            session: _session,
            models: _models,
            onExpandAll: _expandAll,
            onCollapseAll: _collapseAll,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Responsive.centered(
                context,
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mini pipeline flow indicator
                      Container(
                        decoration: AppTheme.cardDecorationOf(context),
                        child: TraceWorkflowWidget(
                          runs: _session.agentRuns,
                          activeAgentName: _session.status == 'RUNNING' &&
                                  _models.isNotEmpty
                              ? _models.last.agentName
                              : null,
                          onAgentTap: (name) =>
                              setState(() => _expanded.add(name)),
                          direction: Axis.horizontal,
                          compact: true,
                        ),
                      ),
                      AppSpacing.gapLg,
                      _buildTimeline(),
                      AppSpacing.gapXl,
                      _ViewReportButton(session: _session),
                      AppSpacing.gapXl,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            Text(
              _session.organizationName,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (_session.status == 'COMPLETED')
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.report,
                  arguments: _session),
              icon: const Icon(Icons.article_outlined, size: 16),
              label: const Text('Report'),
            ),
          const ThemeToggleButton(),
          const SizedBox(width: AppSpacing.sm),
        ],
      );

  Widget _buildTimeline() {
    return Column(
      children: [
        // User entry node
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 260),
          builder: (ctx, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                  offset: Offset(0, 12 * (1 - v)), child: child)),
          child: _UserNode(session: _session),
        ),

        ...List.generate(_kAgentNames.length, (i) {
          final name = _kAgentNames[i];
          final done = i < _models.length;
          final running = i == _models.length && _session.status == 'RUNNING';
          final from = i == 0 ? 'User' : _kAgentNames[i - 1];

          return Column(
            children: [
              _Connector(
                fromName: from,
                toName: name,
                traces: _session.traces,
                completed: done,
                active: running,
              ),
              if (done)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 280 + i * 65),
                  builder: (ctx, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                          offset: Offset(0, 16 * (1 - v)), child: child)),
                  child: _AgentCard(
                    model: _models[i],
                    allTraces: _session.traces,
                    expanded: _expanded.contains(name),
                    onTap: () => _toggle(name),
                  ),
                )
              else if (running)
                _RunningCard(
                  name: _kDisplayNames[i],
                  icon: _kIcons[i],
                  isGemini: !_kRuleBasedIndices.contains(i),
                )
              else
                _WaitingCard(
                  name: _kDisplayNames[i],
                  icon: _kIcons[i],
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ── Status Bar ─────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final SessionResponse session;
  final List<AgentTraceModel> models;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;

  const _StatusBar({
    required this.session,
    required this.models,
    required this.onExpandAll,
    required this.onCollapseAll,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final avgConf = models.isEmpty
        ? 0.0
        : models.fold(0.0, (s, m) => s + m.confidenceScore) / models.length;

    final statusBg = session.status == 'COMPLETED'
        ? AppColors.successLight
        : session.status == 'RUNNING'
            ? AppColors.warningLight
            : AppColors.surfacePage;
    final statusFg = session.status == 'COMPLETED'
        ? AppColors.success
        : session.status == 'RUNNING'
            ? AppColors.warning
            : AppColors.textMuted;

    final chips = <Widget>[
      _Pill(session.status, statusBg, statusFg),
      _Pill('${models.length} / ${_kAgentNames.length} Complete',
          AppColors.brandSubtle, AppColors.brand),
      _Pill('${session.traces.length} Influence Links',
          AppColors.accentSubtle, AppColors.accent),
      if (models.isNotEmpty)
        _Pill(
          'Avg ${(avgConf * 100).toStringAsFixed(0)}% Confidence',
          AppColors.forConfidenceSurface(avgConf),
          AppColors.forConfidence(avgConf),
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: isMobile
          ? Row(
              children: [
                Expanded(
                  child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: chips),
                ),
                IconButton(
                  onPressed: onExpandAll,
                  icon: const Icon(Icons.unfold_more_rounded,
                      size: 18, color: AppColors.textMuted),
                  tooltip: 'Expand all',
                ),
                IconButton(
                  onPressed: onCollapseAll,
                  icon: const Icon(Icons.unfold_less_rounded,
                      size: 18, color: AppColors.textMuted),
                  tooltip: 'Collapse all',
                ),
              ],
            )
          : Row(
              children: [
                ...chips.expand((c) => [c, AppSpacing.hGapSm]),
                const Spacer(),
                TextButton.icon(
                  onPressed: onExpandAll,
                  icon: const Icon(Icons.unfold_more_rounded, size: 14),
                  label: const Text('Expand All',
                      style: TextStyle(fontSize: 12)),
                ),
                AppSpacing.hGapSm,
                TextButton.icon(
                  onPressed: onCollapseAll,
                  icon: const Icon(Icons.unfold_less_rounded, size: 14),
                  label: const Text('Collapse All',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
            color: bg, borderRadius: AppSpacing.roundedPill),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── User Entry Node ────────────────────────────────────────────────────────────

class _UserNode extends StatelessWidget {
  final SessionResponse session;
  const _UserNode({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: AppSpacing.cardPaddingLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 26),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('USER MEETING REQUEST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    )),
                const SizedBox(height: 3),
                Text(session.organizationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    )),
                if (session.meetingObjective?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 5),
                  Text(session.meetingObjective!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.45,
                      )),
                ],
                if (session.stakeholderRole?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  _NodeTag(Icons.badge_outlined,
                      'Stakeholder: ${session.stakeholderRole!}'),
                ],
              ],
            ),
          ),
          const Icon(Icons.rocket_launch_rounded,
              color: Colors.white54, size: 22),
        ],
      ),
    );
  }
}

class _NodeTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _NodeTag(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: AppSpacing.roundedPill,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.28), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Connector ──────────────────────────────────────────────────────────────────

class _Connector extends StatelessWidget {
  final String fromName;
  final String toName;
  final List<AgentTrace> traces;
  final bool completed;
  final bool active;

  const _Connector({
    required this.fromName,
    required this.toName,
    required this.traces,
    required this.completed,
    this.active = false,
  });

  Color get _color {
    if (!completed && !active) return AppColors.outline;
    if (active) return AppColors.accent;
    if (toName == 'CriticValidatorAgent') return AppColors.warning;
    if (toName == 'FinalSynthesisAgent') return AppColors.success;
    return AppColors.brand;
  }

  String? get _influenceDesc {
    if (fromName == 'User') return null;
    for (final t in traces) {
      if (t.sourceAgent == fromName &&
          t.targetAgent == toName &&
          (t.influenceDescription?.isNotEmpty ?? false)) {
        return t.influenceDescription;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final inCount = traces.where((t) => t.targetAgent == toName).length;

    Widget? callout;
    if (completed) {
      if (toName == 'CriticValidatorAgent') {
        callout = _CalloutBox(
          icon: Icons.fact_check_rounded,
          color: AppColors.warning,
          bg: AppColors.warningLight,
          title: 'CRITIC VALIDATION',
          body: _influenceDesc ??
              'CriticValidatorAgent audits all preceding outputs for factual accuracy before final synthesis.',
        );
      } else if (toName == 'FinalSynthesisAgent') {
        callout = _CalloutBox(
          icon: Icons.auto_awesome_rounded,
          color: AppColors.success,
          bg: AppColors.successLight,
          title: 'FINAL SYNTHESIS',
          body: _influenceDesc ??
              'FinalSynthesisAgent integrates validated outputs and critic corrections into the executive brief.',
        );
      } else if (toName == 'ObjectionPredictionAgent') {
        callout = _CalloutBox(
          icon: Icons.psychology_outlined,
          color: AppColors.danger,
          bg: AppColors.dangerLight,
          title: 'OBJECTION CHALLENGE',
          body: _influenceDesc ??
              'ObjectionPredictionAgent challenges the engagement strategy by predicting stakeholder pushback.',
        );
      } else if (inCount > 0) {
        callout = Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brandSubtle.withValues(alpha: 0.45),
            borderRadius: AppSpacing.roundedPill,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.arrow_downward, size: 9,
                color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text('$inCount influence link${inCount > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ]),
        );
      }
    }

    return Column(children: [
      Center(child: Container(width: 2.5, height: 12, color: c)),
      if (callout != null) ...[
        callout,
        Center(child: Container(width: 2.5, height: 8, color: c)),
      ] else
        Center(child: Container(
            width: 7, height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c))),
      Center(child: Container(width: 2.5, height: 8, color: c)),
      Center(child: Icon(Icons.arrow_downward_rounded, size: 14, color: c)),
      const SizedBox(height: 4),
    ]);
  }
}

class _CalloutBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String body;
  const _CalloutBox({
    required this.icon, required this.color, required this.bg,
    required this.title, required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppSpacing.roundedMd,
          border:
              Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 17),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.45)),
                ]),
          ),
        ]),
      );
}

// ── Agent Card ─────────────────────────────────────────────────────────────────

class _AgentCard extends StatelessWidget {
  final AgentTraceModel model;
  final List<AgentTrace> allTraces;
  final bool expanded;
  final VoidCallback onTap;

  const _AgentCard({
    required this.model,
    required this.allTraces,
    required this.expanded,
    required this.onTap,
  });

  bool get _isGemini => model.usedGemini;
  Color get _accent => _isGemini ? AppColors.gemini : AppColors.ruleBased;

  // First meaningful text line from output — used as collapsed preview
  String? get _preview {
    final raw = model.outputGenerated;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      // Try named high-value keys first
      for (final key in [
        'executiveBrief', 'meetingGoal', 'organizationSummary',
        'openingPositioning', 'overallAssessment', 'revisedClaim',
        'communicationStyle', 'decisionLens', 'valueProposition',
        'toneGuidance', 'validationStatus',
      ]) {
        final v = data[key];
        if (v is String && v.length > 25) {
          return v.length > 110 ? '${v.substring(0, 107)}…' : v;
        }
      }
      // Fall back to first qualifying string field
      for (final e in data.entries) {
        if (_kSkipOutputKeys.contains(e.key)) continue;
        if (e.value is String && (e.value as String).length > 25) {
          final t = e.value as String;
          return t.length > 110 ? '${t.substring(0, 107)}…' : t;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = expanded ? _accent : AppColors.outline_(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface_(context),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: borderColor, width: expanded ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: expanded
                ? _accent.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: expanded ? 16 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent stripe when expanded
          if (expanded)
            Container(height: 3, color: _accent),

          // ── Header ─────────────────────────────────────────────────────────
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(children: [
                _OrderBubble(order: model.order, isGemini: _isGemini),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary_(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        AgentTypeBadge(isGemini: _isGemini),
                        AppSpacing.hGapSm,
                        Text(
                          '${(model.executionMs / 1000).toStringAsFixed(1)}s',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary_(context)),
                        ),
                      ]),
                    ],
                  ),
                ),
                _ConfidenceGauge(score: model.confidenceScore),
                AppSpacing.hGapSm,
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.textMuted,
                ),
              ]),
            ),
          ),

          // ── Confidence bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
            child: ClipRRect(
              borderRadius: AppSpacing.roundedPill,
              child: LinearProgressIndicator(
                value: model.confidenceScore,
                minHeight: 5,
                backgroundColor: AppColors.outline_(context),
                valueColor: AlwaysStoppedAnimation(
                    AppColors.forConfidence(model.confidenceScore)),
              ),
            ),
          ),

          // ── Influence flow chips ───────────────────────────────────────────
          if (model.influencedBy.isNotEmpty || model.influencesNext.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (model.influencedBy.isEmpty)
                    _FlowChip(
                      label: 'Pipeline Entrypoint',
                      bg: AppColors.surfacePage,
                      fg: AppColors.textMuted,
                    )
                  else
                    for (final src in model.influencedBy)
                      _FlowChip(
                        label: '↓ ${_kShortNames[src] ?? src}',
                        bg: AppColors.brandLight,
                        fg: AppColors.brand,
                      ),
                  for (final tgt in model.influencesNext)
                    _FlowChip(
                      label: '↑ ${_kShortNames[tgt] ?? tgt}',
                      bg: AppColors.accentSubtle,
                      fg: AppColors.accent,
                    ),
                ],
              ),
            ),

          // ── Collapsed preview ─────────────────────────────────────────────
          if (!expanded && _preview != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 7),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.07),
                  borderRadius: AppSpacing.roundedMd,
                  border: Border(
                      left: BorderSide(color: _accent, width: 3)),
                ),
                child: Text(
                  _preview!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary_(context),
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          // ── Expanded: full output ──────────────────────────────────────────
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: AppSpacing.cardPadding,
              child: _AgentOutputView(
                outputJson: model.outputGenerated ?? '{}',
                accentColor: _accent,
                traceSummary: model.traceSummary,
                context: context,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Agent Output View ──────────────────────────────────────────────────────────
// Parses the agent's return JSON and renders each field as a typed UI widget.
// Never shows raw JSON. All display is structured.

class _AgentOutputView extends StatelessWidget {
  final String outputJson;
  final Color accentColor;
  final String? traceSummary;
  final BuildContext context;

  const _AgentOutputView({
    required this.outputJson,
    required this.accentColor,
    required this.traceSummary,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(outputJson) as Map<String, dynamic>;
    } catch (_) {
      return const _EmptyResult();
    }

    final fields = data.entries
        .where((e) => !_kSkipOutputKeys.contains(e.key))
        .where((e) {
          final v = e.value;
          if (v == null) return false;
          if (v is bool) return false;
          if (v is num) return false;
          if (v is String && v.trim().length < 10) return false;
          if (v is List && (v).isEmpty) return false;
          return true;
        })
        .toList();

    if (fields.isEmpty && traceSummary == null) {
      return const _EmptyResult();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agent influence note (from trace data)
        if (traceSummary != null) ...[
          _SectionHeader(
              icon: Icons.link_rounded,
              label: 'AGENT INFLUENCE',
              color: accentColor),
          AppSpacing.gapSm,
          Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: AppTheme.brandSurfaceOf(ctx),
            child: Text(traceSummary!,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary_(ctx),
                    height: 1.55)),
          ),
          AppSpacing.gapMd,
        ],

        _SectionHeader(
            icon: Icons.output_rounded,
            label: 'AGENT RESULT',
            color: accentColor),
        AppSpacing.gapSm,

        // Render each field with the appropriate typed widget
        for (final entry in fields)
          _renderField(ctx, entry.key, entry.value),
      ],
    );
  }

  Widget _renderField(BuildContext ctx, String key, dynamic value) {
    final label = _toTitle(key);

    // Special: array of objection objects (predictedObjections)
    if (value is List && value.isNotEmpty && value.first is Map) {
      final maps =
          value.cast<Map<String, dynamic>>();

      if (maps.first.containsKey('objection')) {
        return _ObjectionList(label: label, items: maps, accent: accentColor);
      }

      // Critic unsupported claims
      if (maps.first.containsKey('claim') ||
          maps.first.containsKey('riskLevel')) {
        return _CriticIssueList(label: label, items: maps, accent: accentColor);
      }

      // Conversation phases
      if (maps.first.containsKey('phase')) {
        return _PhaseList(label: label, items: maps, accent: accentColor);
      }

      // Generic object list
      return _GenericObjectList(label: label, items: maps, accent: accentColor);
    }

    // Array of strings
    if (value is List) {
      final strings = value.whereType<String>().toList();
      if (strings.isEmpty) return const SizedBox.shrink();
      return _StringList(label: label, items: strings, accent: accentColor);
    }

    // Plain text field
    if (value is String) {
      return _TextField(label: label, text: value, accent: accentColor, ctx: ctx);
    }

    return const SizedBox.shrink();
  }

  static String _toTitle(String key) => key
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ')
      .trim();
}

// ── Output Field Widgets ───────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  final String label;
  final String text;
  final Color accent;
  final BuildContext ctx;
  const _TextField({required this.label, required this.text, required this.accent, required this.ctx});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfacePage,
          borderRadius: AppSpacing.roundedMd,
          border: Border(
            left: BorderSide(color: accent, width: 3),
            top: BorderSide(color: AppColors.outline_(ctx)),
            right: BorderSide(color: AppColors.outline_(ctx)),
            bottom: BorderSide(color: AppColors.outline_(ctx)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.8)),
          const SizedBox(height: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary_(ctx),
                  height: 1.55)),
        ]),
      );
}

class _StringList extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color accent;
  const _StringList({required this.label, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfacePage,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.outline_(context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: accent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary_(context),
                            height: 1.5)),
                  ),
                ]),
              )),
        ]),
      );
}

class _ObjectionList extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final Color accent;
  const _ObjectionList({required this.label, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: accent),
              const SizedBox(width: 4),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.6)),
            ]),
          ),
          ...items.map((obj) => _ObjectionCard(item: obj)),
          const SizedBox(height: AppSpacing.xs),
        ],
      );
}

class _ObjectionCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ObjectionCard({required this.item});

  @override
  State<_ObjectionCard> createState() => _ObjectionCardState();
}

class _ObjectionCardState extends State<_ObjectionCard> {
  bool _showResponse = false;

  @override
  Widget build(BuildContext context) {
    final obj = widget.item;
    final severity = (obj['severity'] as String? ?? '').toUpperCase();
    final likelihood = obj['likelihood'];
    final pct = likelihood is num
        ? '${(likelihood * 100).toStringAsFixed(0)}% likely'
        : null;
    final severityColor = severity == 'HIGH'
        ? AppColors.danger
        : severity == 'MEDIUM'
            ? AppColors.warning
            : AppColors.textMuted;
    final severityBg = severity == 'HIGH'
        ? AppColors.dangerLight
        : severity == 'MEDIUM'
            ? AppColors.warningLight
            : AppColors.surfacePage;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfacePage,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outline_(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Objection header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.smMd, AppSpacing.md, AppSpacing.smMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  obj['objection']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary_(context),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (severity.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: severityBg,
                          borderRadius: AppSpacing.roundedPill),
                      child: Text(severity,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: severityColor)),
                    ),
                  if (pct != null) ...[
                    const SizedBox(height: 3),
                    Text(pct,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Response toggle
        if (obj['response'] != null) ...[
          Divider(height: 1, color: AppColors.outline_(context)),
          InkWell(
            onTap: () =>
                setState(() => _showResponse = !_showResponse),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(children: [
                Icon(
                  _showResponse
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _showResponse
                      ? 'Hide response'
                      : 'Show response',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ),
          if (_showResponse)
            Container(
              width: double.infinity,
              color: AppColors.success.withValues(alpha: 0.06),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.smMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      obj['response'].toString(),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary_(context),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ]),
    );
  }
}

class _CriticIssueList extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final Color accent;
  const _CriticIssueList({required this.label, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.flag_rounded, size: 13, color: accent),
              const SizedBox(width: 4),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.6)),
            ]),
          ),
          ...items.map((item) => _CriticIssueCard(item: item)),
          const SizedBox(height: AppSpacing.xs),
        ],
      );
}

class _CriticIssueCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CriticIssueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final risk = (item['riskLevel'] as String? ?? '').toUpperCase();
    final riskColor = risk == 'HIGH'
        ? AppColors.danger
        : risk == 'MEDIUM'
            ? AppColors.warning
            : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (risk.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.15),
                borderRadius: AppSpacing.roundedPill),
            child: Text('$risk RISK',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: riskColor)),
          ),
        if (item['claim'] != null)
          Text(item['claim'].toString(),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                  height: 1.4)),
        if (item['issue'] != null) ...[
          const SizedBox(height: 6),
          Text(item['issue'].toString(),
              style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary_(context),
                  height: 1.45)),
        ],
        if (item['recommendation'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: AppSpacing.roundedSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 13, color: AppColors.success),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(item['recommendation'].toString(),
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary_(context),
                          height: 1.45)),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

class _PhaseList extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final Color accent;
  const _PhaseList({required this.label, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.view_timeline_outlined, size: 13, color: accent),
              const SizedBox(width: 4),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.6)),
            ]),
          ),
          ...items.asMap().entries.map((e) {
            final step = e.key + 1;
            final item = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surfacePage,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.outline_(context)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$step',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['phase'] != null)
                          Text(item['phase'].toString(),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary_(context))),
                        if (item['duration'] != null)
                          Text(item['duration'].toString(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        if (item['approach'] != null) ...[
                          const SizedBox(height: 5),
                          Text(item['approach'].toString(),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary_(context),
                                  height: 1.45)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
        ],
      );
}

class _GenericObjectList extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final Color accent;
  const _GenericObjectList({required this.label, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.list_alt_rounded, size: 13, color: accent),
              const SizedBox(width: 4),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.6)),
            ]),
          ),
          ...items.map((obj) {
            final first = obj.values
                .whereType<String>()
                .where((s) => s.length > 10)
                .cast<String?>()
                .firstOrNull;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surfacePage,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.outline_(context)),
              ),
              child: Text(first ?? obj.toString(),
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary_(context),
                      height: 1.45)),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
        ],
      );
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) => Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfacePage,
          borderRadius: AppSpacing.roundedMd,
        ),
        child: const Text('No output data available.',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic)),
      );
}

// ── Running / Waiting Cards ────────────────────────────────────────────────────

class _RunningCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final bool isGemini;
  const _RunningCard({required this.name, required this.icon, required this.isGemini});

  @override
  State<_RunningCard> createState() => _RunningCardState();
}

class _RunningCardState extends State<_RunningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = widget.isGemini
        ? AppColors.geminiSurface
        : AppColors.ruleBasedSurface;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface_(context),
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(
              color: fg.withValues(alpha: 0.30 + 0.70 * _ctrl.value),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: fg.withValues(alpha: 0.06 * _ctrl.value),
                blurRadius: 10,
                spreadRadius: 2)
          ],
        ),
        padding: AppSpacing.cardPaddingLg,
        child: child,
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(widget.icon, color: fg, size: 16),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              AgentTypeBadge(isGemini: widget.isGemini),
              AppSpacing.hGapSm,
              const Text('Running…',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
        const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final String name;
  final IconData icon;
  const _WaitingCard({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.40,
        child: Container(
          decoration: AppTheme.cardDecorationOf(context),
          padding: AppSpacing.cardPadding,
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  color: AppColors.outline, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.textMuted, size: 15),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    const Text('Awaiting preceding agents…',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ]),
            ),
            const Icon(Icons.lock_outline,
                size: 14, color: AppColors.textMuted),
          ]),
        ),
      );
}

// ── View Report Button ─────────────────────────────────────────────────────────

class _ViewReportButton extends StatelessWidget {
  final SessionResponse session;
  const _ViewReportButton({required this.session});

  @override
  Widget build(BuildContext context) {
    if (session.finalReport == null) return const SizedBox.shrink();
    final conf = session.finalReport!.overallConfidence;

    return Container(
      decoration: AppTheme.heroDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Column(children: [
        const Icon(Icons.verified_user_rounded,
            color: Colors.white, size: 40),
        AppSpacing.gapSm,
        const Text('Meeting Strategy Brief Ready',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        AppSpacing.gapXs,
        Text(
          '${_kAgentNames.length} agents completed · '
          'CriticValidator approved · '
          '${(conf * 100).toStringAsFixed(0)}% overall confidence',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12.5,
              height: 1.45),
        ),
        AppSpacing.gapLg,
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, Routes.report,
                arguments: session),
            icon: const Icon(Icons.article_outlined, size: 18),
            label: const Text('View Final Report'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Small Helpers ──────────────────────────────────────────────────────────────

class _ConfidenceGauge extends StatelessWidget {
  final double score;
  const _ConfidenceGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: score),
      duration: const Duration(milliseconds: 700),
      builder: (ctx, val, _) {
        final color = AppColors.forConfidence(val);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${(val * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5)),
              const Text('CONFIDENCE',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted)),
            ],
          ),
          AppSpacing.hGapSm,
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: val,
              color: color,
              backgroundColor: AppColors.forConfidenceSubtle(val),
              strokeWidth: 3,
            ),
          ),
        ]);
      },
    );
  }
}

class _OrderBubble extends StatelessWidget {
  final int order;
  final bool isGemini;
  const _OrderBubble({required this.order, required this.isGemini});

  @override
  Widget build(BuildContext context) {
    final fg = isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: fg, width: 1.5)),
      alignment: Alignment.center,
      child: Text('$order',
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _FlowChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _FlowChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
            color: bg, borderRadius: AppSpacing.roundedPill),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.6)),
      ]);
}
