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
import '../widgets/error_view.dart';
import '../widgets/trace_workflow_widget.dart';

// ── Agent Metadata & Short names ──────────────────────────────────────────────

const Map<String, String> _kShortNames = {
  'OrganizationResearchAgent': 'Research',
  'StakeholderPersonaAgent': 'Persona',
  'EngagementStrategyAgent': 'Strategy',
  'ObjectionPredictionAgent': 'Objection',
  'CriticValidatorAgent': 'Critic',
  'FinalSynthesisAgent': 'Synthesis',
};

const List<String> _kAgentNames = [
  'OrganizationResearchAgent',
  'StakeholderPersonaAgent',
  'EngagementStrategyAgent',
  'ObjectionPredictionAgent',
  'CriticValidatorAgent',
  'FinalSynthesisAgent',
];

const List<String> _kDisplayNames = [
  'Organization Research Agent',
  'Stakeholder Persona Agent',
  'Engagement Strategy Agent',
  'Objection Prediction Agent',
  'Critic Validator Agent',
  'Final Synthesis Agent',
];

const List<IconData> _kIcons = [
  Icons.search_outlined,
  Icons.person_outlined,
  Icons.lightbulb_outline,
  Icons.warning_amber_outlined,
  Icons.fact_check_outlined,
  Icons.summarize_outlined,
];

// ── Screen ────────────────────────────────────────────────────────────────────

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
  final Set<String> _showInput = {};
  final Set<String> _showOutput = {};
  String? _selectedAgent;
  String? _pollError;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _models = AgentTraceModel.fromSession(_session);

    // Auto-expand interesting agents for the demo story if completed
    _autoExpandKeys();

    // Start polling the server if the session is currently running
    if (_session.status == 'RUNNING') {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _autoExpandKeys() {
    if (_session.status == 'COMPLETED') {
      _expanded.add('CriticValidatorAgent');
      _expanded.add('FinalSynthesisAgent');
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
            _autoExpandKeys();
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _pollError = 'Connection lost. Retrying...';
          });
        }
      }
    });
  }

  void _toggleExpand(String name) =>
      setState(() => _expanded.contains(name)
          ? _expanded.remove(name)
          : _expanded.add(name));

  void _toggleInput(String name) =>
      setState(() => _showInput.contains(name)
          ? _showInput.remove(name)
          : _showInput.add(name));

  void _toggleOutput(String name) =>
      setState(() => _showOutput.contains(name)
          ? _showOutput.remove(name)
          : _showOutput.add(name));

  void _expandAll() =>
      setState(() => _expanded.addAll(_models.map((m) => m.agentName)));

  void _collapseAll() => setState(() => _expanded.clear());

  void _onPipelineTap(String agentName) {
    setState(() {
      _selectedAgent = _selectedAgent == agentName ? null : agentName;
      _expanded.add(agentName);
    });
  }

  @override
  Widget build(BuildContext context) {

    // Empty state fallback (no agents run and status is not running)
    if (_models.isEmpty && _session.status != 'RUNNING') {
      return Scaffold(
        appBar: _buildAppBar(),
        body: ErrorView(
          compact: false,
          isError: false,
          icon: Icons.account_tree_outlined,
          title: 'No Pipeline Traces',
          message: 'No execution trace logs exist for this meeting brief.',
          onRetry: () => Navigator.pop(context),
          retryLabel: 'Go Back',
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_pollError != null)
            Container(
              color: AppColors.danger,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.md),
              alignment: Alignment.center,
              child: Text(
                _pollError!,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          _HeaderBar(
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
                      // Active visual pipeline indicator
                      Container(
                        decoration: AppTheme.cardDecoration,
                        child: TraceWorkflowWidget(
                          runs: _session.agentRuns,
                          activeAgentName: _selectedAgent ?? 
                              (_session.status == 'RUNNING' && _models.isNotEmpty 
                                  ? _models.last.agentName 
                                  : null),
                          onAgentTap: _onPipelineTap,
                          direction: Axis.horizontal,
                          compact: true,
                        ),
                      ),
                      AppSpacing.gapLg,
                      
                      // Live dynamic timeline list
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

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: Text('Agent Execution Trace — ${_session.organizationName}'),
        actions: [
          if (_session.status == 'COMPLETED')
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                  context, Routes.report,
                  arguments: _session),
              icon: const Icon(Icons.article_outlined, size: 16),
              label: const Text('Final Report'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      );

  Widget _buildTimeline() {
    return Column(
      children: List.generate(6, (index) {
        final agentName = _kAgentNames[index];
        final isCompleted = index < _models.length;
        final isActive = index == _models.length && _session.status == 'RUNNING';

        if (isCompleted) {
          final model = _models[index];
          return Column(
            children: [
              if (index > 0)
                _TraceConnector(
                  fromName: _kAgentNames[index - 1],
                  toName: agentName,
                  traces: _session.traces,
                  completed: true,
                ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _AgentCard(
                  model: model,
                  allTraces: _session.traces,
                  expanded: _expanded.contains(agentName),
                  showInput: _showInput.contains(agentName),
                  showOutput: _showOutput.contains(agentName),
                  onToggleExpand: () => _toggleExpand(agentName),
                  onToggleInput: () => _toggleInput(agentName),
                  onToggleOutput: () => _toggleOutput(agentName),
                ),
              ),
            ],
          );
        } else if (isActive) {
          return Column(
            children: [
              _TraceConnector(
                fromName: _kAgentNames[index - 1],
                toName: agentName,
                traces: const [],
                completed: false,
                active: true,
              ),
              _RunningAgentCard(
                name: _kDisplayNames[index],
                order: index + 1,
                icon: _kIcons[index],
                isGemini: index != 1 && index != 4,
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _TraceConnector(
                fromName: _kAgentNames[index - 1],
                toName: agentName,
                traces: const [],
                completed: false,
              ),
              _UpcomingAgentCard(
                name: _kDisplayNames[index],
                order: index + 1,
                icon: _kIcons[index],
                isGemini: index != 1 && index != 4,
              ),
            ],
          );
        }
      }),
    );
  }
}

// ── Header bar ────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final SessionResponse session;
  final List<AgentTraceModel> models;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;

  const _HeaderBar({
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
        : models.map((m) => m.confidenceScore).reduce((a, b) => a + b) /
            models.length;

    final chips = <Widget>[
      _Chip(session.status, session.status == 'COMPLETED' ? AppColors.successLight : AppColors.warningLight, session.status == 'COMPLETED' ? AppColors.success : AppColors.warning),
      _Chip('${models.length} / 6 Run', AppColors.brandSubtle, AppColors.brand),
      _Chip('${session.traces.length} Influence Traces', AppColors.accentSubtle, AppColors.accent),
      if (models.isNotEmpty)
        _Chip(
          'Avg Conf: ${(avgConf * 100).toStringAsFixed(0)}%',
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: chips,
                  ),
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
                    label: const Text('Expand All', style: TextStyle(fontSize: 12))),
                AppSpacing.hGapSm,
                TextButton.icon(
                    onPressed: onCollapseAll,
                    icon: const Icon(Icons.unfold_less_rounded, size: 14),
                    label: const Text('Collapse All', style: TextStyle(fontSize: 12))),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Chip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(color: bg, borderRadius: AppSpacing.roundedPill),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── Trace Connector ───────────────────────────────────────────────────────────

class _TraceConnector extends StatelessWidget {
  final String fromName;
  final String toName;
  final List<AgentTrace> traces;
  final bool completed;
  final bool active;

  const _TraceConnector({
    required this.fromName,
    required this.toName,
    required this.traces,
    required this.completed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    Color lineColor = AppColors.outline;
    if (completed) {
      if (toName == 'CriticValidatorAgent') {
        lineColor = AppColors.warning;
      } else if (toName == 'FinalSynthesisAgent') {
        lineColor = AppColors.success;
      } else {
        lineColor = AppColors.brand;
      }
    } else if (active) {
      lineColor = AppColors.accent;
    }

    return Column(
      children: [
        // Top stem connector
        Center(
          child: Container(
            width: 2.5,
            height: 16,
            color: lineColor,
          ),
        ),
        
        // Dynamic callout for key agent-to-agent interactions
        if (completed && toName == 'CriticValidatorAgent')
          _buildHighlightBox(
            icon: Icons.fact_check_rounded,
            color: AppColors.danger,
            bg: AppColors.dangerLight,
            title: 'Critic Validation Layer',
            desc: 'CriticValidatorAgent reads the predicted objections and strategy files to audit statements against validated references.',
          )
        else if (completed && toName == 'FinalSynthesisAgent')
          _buildHighlightBox(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.success,
            bg: AppColors.successLight,
            title: 'Audit Trigger: Revision Applied',
            desc: 'CriticValidator flagged an integration claim. FinalSynthesisAgent rewrites the McKesson vendor reference before client delivery.',
          )
        else if (completed && toName == 'ObjectionPredictionAgent')
          _buildHighlightBox(
            icon: Icons.psychology_outlined,
            color: AppColors.warning,
            bg: AppColors.warningLight,
            title: 'Objection Framing',
            desc: 'ObjectionPredictionAgent challenges the Engagement Strategy by predicting stakeholder pushback on system interoperability.',
          )
        else if (completed && traces.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfacePage,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward, size: 10, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${traces.where((t) => t.targetAgent == toName).length} Inbound Link(s)',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lineColor,
            ),
          ),

        // Bottom stem connector
        Center(
          child: Container(
            width: 2.5,
            height: 16,
            color: lineColor,
          ),
        ),
        Center(
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 16,
            color: lineColor,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildHighlightBox({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agent Card ────────────────────────────────────────────────────────────────

class _AgentCard extends StatelessWidget {
  final AgentTraceModel model;
  final List<AgentTrace> allTraces;
  final bool expanded;
  final bool showInput;
  final bool showOutput;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleInput;
  final VoidCallback onToggleOutput;

  const _AgentCard({
    required this.model,
    required this.allTraces,
    required this.expanded,
    required this.showInput,
    required this.showOutput,
    required this.onToggleExpand,
    required this.onToggleInput,
    required this.onToggleOutput,
  });

  List<AgentTrace> get _inbound =>
      allTraces.where((t) => t.targetAgent == model.agentName).toList();

  List<AgentTrace> get _outbound =>
      allTraces.where((t) => t.sourceAgent == model.agentName).toList();

  @override
  Widget build(BuildContext context) {
    final isGemini = model.usedGemini;
    final borderColor = expanded
        ? (isGemini ? AppColors.brand : AppColors.ruleBased)
        : AppColors.outline;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: borderColor,
          width: expanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: expanded ? 0.06 : 0.02),
            blurRadius: expanded ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  _OrderBubble(order: model.order, isGemini: isGemini),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.displayName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            AgentTypeBadge(isGemini: isGemini),
                            AppSpacing.hGapSm,
                            Text(
                              '${(model.executionMs / 1000).toStringAsFixed(1)}s runtime',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildAnimatedScoreGauge(model.confidenceScore),
                  AppSpacing.hGapSm,
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Confidence indicator linear progress
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
            child: ClipRRect(
              borderRadius: AppSpacing.roundedPill,
              child: LinearProgressIndicator(
                value: model.confidenceScore,
                minHeight: 5,
                backgroundColor: AppColors.outline,
                valueColor: AlwaysStoppedAnimation(AppColors.forConfidence(model.confidenceScore)),
              ),
            ),
          ),

          // Interdependency Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (model.influencedBy.isEmpty)
                  _MiniChip(
                    label: 'Pipeline Entrypoint',
                    bg: AppColors.surfacePage,
                    fg: AppColors.textMuted,
                  )
                else
                  for (final src in model.influencedBy)
                    _MiniChip(
                      label: 'Reads ${_kShortNames[src] ?? src}',
                      bg: AppColors.brandLight,
                      fg: AppColors.brand,
                    ),
                if (model.influencesNext.isNotEmpty)
                  for (final tgt in model.influencesNext)
                    _MiniChip(
                      label: 'Feeds ${_kShortNames[tgt] ?? tgt}',
                      bg: AppColors.accentSubtle,
                      fg: AppColors.accent,
                    ),
              ],
            ),
          ),

          // Extended Trace details
          if (expanded) ...[
            const Divider(),
            
            // Custom callouts inside card for demo highlights
            if (model.agentName == 'ObjectionPredictionAgent')
              _buildCallout(
                title: 'AGENT CHALLENGE ANALYSIS',
                text: 'Critic validator matched objections back to the EMR vendor platform mapping. Interoperability objections were flagged as the primary friction point.',
                color: AppColors.warning,
                bg: AppColors.warningLight,
              ),
            if (model.agentName == 'CriticValidatorAgent')
              _buildCallout(
                title: 'CRITIC AUDIT LOG',
                text: 'FLAGGED CLAIM: "MEDplat is fully compatible with McKesson EMR". CORRECTION: McKesson API support is in beta. Replaced with conditional EMR vendor tiering.',
                color: AppColors.danger,
                bg: AppColors.dangerLight,
              ),
            if (model.agentName == 'FinalSynthesisAgent')
              _buildCallout(
                title: 'SYNTHESIS VERIFICATION',
                text: 'Applied CriticValidator modification directly to Next Steps and Conversation Playbook. Final readiness score finalized at 88%.',
                color: AppColors.success,
                bg: AppColors.successLight,
              ),

            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_inbound.isNotEmpty) ...[
                    _SectionLabel(
                      icon: Icons.subdirectory_arrow_right,
                      label: 'INBOUND COLLABORATIONS',
                      color: AppColors.brand,
                    ),
                    AppSpacing.gapSm,
                    ..._inbound.map((t) => _TraceRow(trace: t, isInbound: true)),
                    AppSpacing.gapMd,
                  ],
                  if (_outbound.isNotEmpty) ...[
                    _SectionLabel(
                      icon: Icons.subdirectory_arrow_left,
                      label: 'OUTBOUND DEPENDENCIES',
                      color: AppColors.accent,
                    ),
                    AppSpacing.gapSm,
                    ..._outbound.map((t) => _TraceRow(trace: t, isInbound: false)),
                    AppSpacing.gapMd,
                  ],
                  if (model.traceSummary != null) ...[
                    _SectionLabel(
                      icon: Icons.summarize_outlined,
                      label: 'INFLUENCE LOG SUMMARY',
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapSm,
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPadding,
                      decoration: AppTheme.brandSurface,
                      child: Text(
                        model.traceSummary!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.55),
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],
                  
                  // JSON toggles
                  if (model.inputReceived != null)
                    _JsonSection(
                      label: 'INPUT PAYLOAD JSON',
                      json: model.inputReceived!,
                      visible: showInput,
                      onToggle: onToggleInput,
                    ),
                  _JsonSection(
                    label: 'OUTPUT RESPONSE JSON',
                    json: model.outputGenerated ?? '{}',
                    visible: showOutput,
                    onToggle: onToggleOutput,
                    accent: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedScoreGauge(double score) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: score),
      duration: const Duration(milliseconds: 600),
      builder: (context, val, _) {
        final color = AppColors.forConfidence(val);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(val * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'CONFIDENCE',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
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
          ],
        );
      },
    );
  }

  Widget _buildCallout({
    required String title,
    required String text,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Active running card ───────────────────────────────────────────────────────

class _RunningAgentCard extends StatefulWidget {
  final String name;
  final int order;
  final IconData icon;
  final bool isGemini;

  const _RunningAgentCard({
    required this.name,
    required this.order,
    required this.icon,
    required this.isGemini,
  });

  @override
  State<_RunningAgentCard> createState() => _RunningAgentCardState();
}

class _RunningAgentCardState extends State<_RunningAgentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = widget.isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(
              color: fg.withValues(alpha: 0.3 + (0.7 * _controller.value)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: fg.withValues(alpha: 0.05 * _controller.value),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: AppSpacing.cardPaddingLg,
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: fg, size: 16),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AgentTypeBadge(isGemini: widget.isGemini),
                    AppSpacing.hGapSm,
                    const Text(
                      'Running multi-agent orchestration...',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming deactivated card ──────────────────────────────────────────────────

class _UpcomingAgentCard extends StatelessWidget {
  final String name;
  final int order;
  final IconData icon;
  final bool isGemini;

  const _UpcomingAgentCard({
    required this.name,
    required this.order,
    required this.icon,
    required this.isGemini,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.outline,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 15),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Waiting on preceding agents output...',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── View Report Button ────────────────────────────────────────────────────────

class _ViewReportButton extends StatelessWidget {
  final SessionResponse session;

  const _ViewReportButton({required this.session});

  @override
  Widget build(BuildContext context) {
    if (session.finalReport == null) return const SizedBox.shrink();

    return Container(
      decoration: AppTheme.heroDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
          AppSpacing.gapSm,
          const Text(
            'Meeting Strategy Brief Completed',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          AppSpacing.gapXs,
          Text(
            'Pipeline audited and validated by CriticValidatorAgent · Final report ready for review',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
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
              label: const Text('Access Executive Briefing'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.smMd),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small Reusable Helpers ───────────────────────────────────────────────────

class _OrderBubble extends StatelessWidget {
  final int order;
  final bool isGemini;

  const _OrderBubble({required this.order, required this.isGemini});

  @override
  Widget build(BuildContext context) {
    final fg = isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$order',
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MiniChip(
      {required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
            color: bg, borderRadius: AppSpacing.roundedPill),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg)),
      );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.6),
          ),
        ],
      );
}

class _TraceRow extends StatelessWidget {
  final AgentTrace trace;
  final bool isInbound;

  const _TraceRow({required this.trace, required this.isInbound});

  @override
  Widget build(BuildContext context) {
    final agentName =
        isInbound ? trace.sourceAgent : trace.targetAgent;
    final short = _kShortNames[agentName] ?? agentName;
    final fg = isInbound ? AppColors.brand : AppColors.accent;
    final bg = isInbound ? AppColors.brandSubtle : AppColors.accentSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.25),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
                color: bg, borderRadius: AppSpacing.roundedPill),
            child: Text(
              short,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: fg),
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              trace.influenceDescription ??
                  (isInbound
                      ? 'Provided input context to this agent'
                      : 'Received output from this agent'),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonSection extends StatelessWidget {
  final String label;
  final String json;
  final bool visible;
  final VoidCallback onToggle;
  final bool accent;

  const _JsonSection({
    required this.label,
    required this.json,
    required this.visible,
    required this.onToggle,
    this.accent = false,
  });

  static String _prettyPrint(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = accent ? AppColors.accent : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  _SectionLabel(
                      icon: accent
                          ? Icons.output_rounded
                          : Icons.input_rounded,
                      label: label,
                      color: fg),
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePage,
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(
                      visible ? 'Hide JSON' : 'Show JSON',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (visible) ...[
            AppSpacing.gapSm,
            Container(
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: AppTheme.codeDecoration,
              child: SelectableText(
                _prettyPrint(json),
                style: AppTheme.monoStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
