import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
import '../models/agent_trace_model.dart';
import '../models/session_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_card.dart';
import '../widgets/error_view.dart';
import '../widgets/trace_workflow_widget.dart';

// ── Agent metadata ────────────────────────────────────────────────────────────

const Map<String, String> _kShort = {
  'OrganizationResearchAgent': 'Research',
  'StakeholderPersonaAgent': 'Persona',
  'EngagementStrategyAgent': 'Strategy',
  'ObjectionPredictionAgent': 'Objection',
  'CriticValidatorAgent': 'Critic',
  'FinalSynthesisAgent': 'Synthesis',
};

class _HighlightDef {
  final IconData icon;
  final Color fg;
  final Color bg;
  final String title;
  final String body;

  const _HighlightDef({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.body,
  });
}

const Map<String, _HighlightDef> _kHighlights = {
  'ObjectionPredictionAgent': _HighlightDef(
    icon: Icons.warning_amber_rounded,
    fg: AppColors.warning,
    bg: AppColors.warningLight,
    title: 'Challenges Strategy Agent',
    body:
        'Every objection is anchored in the engagement framing from EngagementStrategy. The "unification layer, not replacement" positioning is what surfaced the interoperability challenge.',
  ),
  'CriticValidatorAgent': _HighlightDef(
    icon: Icons.fact_check_rounded,
    fg: AppColors.danger,
    bg: AppColors.dangerLight,
    title: 'Validates Weaknesses Across All Agents',
    body:
        'Reviewed all 4 prior outputs. Flagged 1 HIGH-risk unsupported claim in ObjectionPrediction: "100% interoperability" cannot be substantiated for the specific EMR vendors identified by OrgResearch.',
  ),
  'FinalSynthesisAgent': _HighlightDef(
    icon: Icons.auto_awesome_rounded,
    fg: AppColors.success,
    bg: AppColors.successLight,
    title: 'Synthesizes Refined Output',
    body:
        'Incorporated all 5 prior agents. Applied CriticValidator revision: replaced "100% interoperability" with per-vendor connector status — TASY (production-ready) and McKesson Paragon (beta, 30-day GA).',
  ),
};

class _ConnectorDef {
  final Color line;
  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
  final String desc;

  const _ConnectorDef({
    required this.line,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
    required this.desc,
  });
}

// Special connectors that appear ABOVE the target agent card
const Map<String, _ConnectorDef> _kConnectors = {
  'CriticValidatorAgent': _ConnectorDef(
    line: AppColors.warning,
    bg: AppColors.warningLight,
    fg: AppColors.warning,
    icon: Icons.fact_check_rounded,
    label: 'Critic reviews Objection claims',
    desc: 'CriticValidator examines all prior outputs including ObjectionPrediction\'s responses.',
  ),
  'FinalSynthesisAgent': _ConnectorDef(
    line: AppColors.success,
    bg: AppColors.successLight,
    fg: AppColors.success,
    icon: Icons.auto_awesome_rounded,
    label: '1 HIGH-risk finding → Final revises',
    desc: 'CriticValidator\'s flag is directly incorporated — this is the key interdependency.',
  ),
};

// ── Screen ────────────────────────────────────────────────────────────────────

class AgentTraceScreen extends StatefulWidget {
  final SessionResponse session;

  const AgentTraceScreen({super.key, required this.session});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  final Set<String> _expanded = {};
  final Set<String> _showInput = {};
  final Set<String> _showOutput = {};
  String? _selectedAgent;

  late final List<AgentTraceModel> _models;

  @override
  void initState() {
    super.initState();
    _models = AgentTraceModel.fromSession(widget.session);
    // Auto-expand Critic and Final for the demo story
    if (_models.isNotEmpty) {
      _expanded.add('CriticValidatorAgent');
      _expanded.add('FinalSynthesisAgent');
    }
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
      // Also expand the tapped card
      _expanded.add(agentName);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Empty-state guard — show before any pipeline UI to avoid blank screen.
    if (_models.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: ErrorView(
          compact: false,
          isError: false,
          icon: Icons.account_tree_outlined,
          title: 'No Agent Data',
          message:
              'This session has no agent run records. '
              'The pipeline may not have completed or data may be unavailable.',
          onRetry: () => Navigator.pop(context),
          retryLabel: 'Go Back',
          onSecondary: () => Navigator.pushNamedAndRemoveUntil(
              context, Routes.home, (_) => false),
          secondaryLabel: 'Go to Home',
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _HeaderBar(
            session: widget.session,
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
                      // Pipeline overview strip — tap a node to expand its card
                      Container(
                        decoration: AppTheme.cardDecoration,
                        child: TraceWorkflowWidget(
                          runs: widget.session.agentRuns,
                          activeAgentName: _selectedAgent,
                          onAgentTap: _onPipelineTap,
                          direction: Axis.horizontal,
                          compact: true,
                        ),
                      ),
                      AppSpacing.gapLg,
                      for (var i = 0; i < _models.length; i++) ...[
                        if (i > 0)
                          _TraceConnector(
                            fromName: _models[i - 1].agentName,
                            toName: _models[i].agentName,
                            traces: widget.session.traces,
                          ),
                        _AgentCard(
                          model: _models[i],
                          allTraces: widget.session.traces,
                          expanded: _expanded.contains(_models[i].agentName),
                          showInput: _showInput.contains(_models[i].agentName),
                          showOutput:
                              _showOutput.contains(_models[i].agentName),
                          onToggleExpand: () =>
                              _toggleExpand(_models[i].agentName),
                          onToggleInput: () =>
                              _toggleInput(_models[i].agentName),
                          onToggleOutput: () =>
                              _toggleOutput(_models[i].agentName),
                        ),
                      ],
                      AppSpacing.gapXl,
                      _ViewReportButton(session: widget.session),
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
        title: Text('Agent Trace — ${widget.session.organizationName}'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, Routes.report,
                arguments: widget.session),
            icon: const Icon(Icons.article_outlined, size: 16),
            label: const Text('Final Report'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      );
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
    final geminiCount = models.where((m) => m.usedGemini).length;
    final ruleCount = models.length - geminiCount;
    final avgConf = models.isEmpty
        ? 0.0
        : models.map((m) => m.confidenceScore).reduce((a, b) => a + b) /
            models.length;

    final chips = <Widget>[
      _Chip('${models.length} Agents', AppColors.brandSubtle, AppColors.brand),
      _Chip('${session.traces.length} Traces', AppColors.accentSubtle, AppColors.accent),
      _Chip('$geminiCount Gemini', AppColors.geminiSurface, AppColors.gemini),
      _Chip('$ruleCount Rules', AppColors.ruleBasedSurface, AppColors.ruleBased),
      _Chip(
        '${(avgConf * 100).toStringAsFixed(0)}% avg',
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
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  onPressed: onCollapseAll,
                  icon: const Icon(Icons.unfold_less_rounded,
                      size: 18, color: AppColors.textMuted),
                  tooltip: 'Collapse all',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            )
          : Row(
              children: [
                ...chips.expand((c) => [c, AppSpacing.hGapSm]),
                const Spacer(),
                TextButton(
                    onPressed: onExpandAll,
                    child: const Text('Expand all',
                        style: TextStyle(fontSize: 12))),
                TextButton(
                    onPressed: onCollapseAll,
                    child: const Text('Collapse all',
                        style: TextStyle(fontSize: 12))),
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

// ── Trace connector (visual arrow between cards) ───────────────────────────────

class _TraceConnector extends StatelessWidget {
  final String fromName;
  final String toName;
  final List<AgentTrace> traces;

  const _TraceConnector({
    required this.fromName,
    required this.toName,
    required this.traces,
  });

  @override
  Widget build(BuildContext context) {
    final def = _kConnectors[toName];
    final lineColor = def?.line ?? AppColors.outline;

    return Column(
      children: [
        // Top stem
        Center(
          child: Container(
              width: 2,
              height: 16,
              color: lineColor),
        ),
        // Special highlight connector
        if (def != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: def.bg,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: def.fg.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(def.icon, color: def.fg, size: 18),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.label,
                        style: TextStyle(
                            color: def.fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        def.desc,
                        style: TextStyle(
                            color: def.fg.withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Simple trace count pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: const BoxDecoration(
              color: AppColors.surfacePage,
              borderRadius: AppSpacing.roundedPill,
              border: Border.fromBorderSide(
                  BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward,
                    size: 10, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${traces.where((t) => t.targetAgent == toName).length} influence links',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
        // Bottom stem
        Center(
          child: Container(
              width: 2,
              height: 16,
              color: lineColor),
        ),
        Center(
          child: Icon(Icons.arrow_downward_rounded,
              size: 16, color: lineColor),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Agent card ────────────────────────────────────────────────────────────────

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
    final highlight = _kHighlights[model.agentName];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
            color: borderColor,
            width: expanded ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (always visible) ─────────────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Order bubble
                  _OrderBubble(
                      order: model.order, isGemini: isGemini),
                  AppSpacing.hGapMd,
                  // Name + type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.displayName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            AgentTypeBadge(isGemini: isGemini),
                            AppSpacing.hGapSm,
                            Text(
                              '${model.executionMs}ms',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Confidence
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(model.confidenceScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forConfidence(
                                model.confidenceScore)),
                      ),
                      Text(
                        'confidence',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  AppSpacing.hGapSm,
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Confidence bar (always visible) ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
            child: ClipRRect(
              borderRadius: AppSpacing.roundedPill,
              child: LinearProgressIndicator(
                value: model.confidenceScore,
                minHeight: 5,
                backgroundColor: AppColors.forConfidenceSubtle(
                    model.confidenceScore),
                valueColor: AlwaysStoppedAnimation(
                    AppColors.forConfidence(model.confidenceScore)),
              ),
            ),
          ),

          // ── Influence chip row (always visible) ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.smMd),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (model.influencedBy.isEmpty)
                  _MiniChip(
                    label: '← No inputs',
                    bg: AppColors.surfacePage,
                    fg: AppColors.textMuted,
                  )
                else
                  for (final src in model.influencedBy)
                    _MiniChip(
                      label: '← ${_kShort[src] ?? src}',
                      bg: AppColors.brandSubtle,
                      fg: AppColors.brand,
                    ),
                if (model.influencesNext.isEmpty)
                  _MiniChip(
                    label: '→ No outputs',
                    bg: AppColors.surfacePage,
                    fg: AppColors.textMuted,
                  )
                else
                  for (final tgt in model.influencesNext)
                    _MiniChip(
                      label: '→ ${_kShort[tgt] ?? tgt}',
                      bg: AppColors.accentSubtle,
                      fg: AppColors.accent,
                    ),
              ],
            ),
          ),

          // ── Expanded content ────────────────────────────────────────────
          if (expanded) ...[
            const Divider(height: 1),

            // Highlight banner for key agents
            if (highlight != null)
              _HighlightBanner(def: highlight),

            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INBOUND TRACES
                  if (_inbound.isNotEmpty) ...[
                    _SectionLabel(
                      icon: Icons.arrow_downward_rounded,
                      label: 'INFLUENCED BY',
                      color: AppColors.brand,
                    ),
                    AppSpacing.gapSm,
                    ..._inbound.map((t) => _TraceRow(
                          trace: t,
                          isInbound: true,
                        )),
                    AppSpacing.gapMd,
                  ],

                  // OUTBOUND TRACES
                  if (_outbound.isNotEmpty) ...[
                    _SectionLabel(
                      icon: Icons.arrow_upward_rounded,
                      label: 'INFLUENCES NEXT',
                      color: AppColors.accent,
                    ),
                    AppSpacing.gapSm,
                    ..._outbound.map((t) => _TraceRow(
                          trace: t,
                          isInbound: false,
                        )),
                    AppSpacing.gapMd,
                  ],

                  // TRACE SUMMARY
                  if (model.traceSummary != null) ...[
                    _SectionLabel(
                      icon: Icons.summarize_outlined,
                      label: 'TRACE SUMMARY',
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
                            height: 1.5),
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],

                  // INPUT JSON
                  if (model.inputReceived != null)
                    _JsonSection(
                      label: 'INPUT RECEIVED',
                      json: model.inputReceived!,
                      visible: showInput,
                      onToggle: onToggleInput,
                    ),

                  // OUTPUT JSON
                  _JsonSection(
                    label: 'OUTPUT GENERATED',
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
}

// ── View Report button ────────────────────────────────────────────────────────

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
          const Icon(Icons.article_rounded, color: Colors.white, size: 32),
          AppSpacing.gapSm,
          const Text(
            'Meeting Strategy Ready',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          AppSpacing.gapXs,
          Text(
            'All 6 agents completed · ${session.traces.length} influence links recorded · CriticValidator revision applied',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4),
          ),
          AppSpacing.gapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                  context, Routes.report,
                  arguments: session),
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('View Final Meeting Report'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.smMd),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OrderBubble extends StatelessWidget {
  final int order;
  final bool isGemini;

  const _OrderBubble({required this.order, required this.isGemini});

  @override
  Widget build(BuildContext context) {
    final fg = isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$order',
        style: TextStyle(
            color: fg, fontSize: 14, fontWeight: FontWeight.w800),
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
                fontWeight: FontWeight.w600,
                color: fg)),
      );
}

class _HighlightBanner extends StatelessWidget {
  final _HighlightDef def;

  const _HighlightBanner({required this.def});

  @override
  Widget build(BuildContext context) => Container(
        padding: AppSpacing.cardPadding,
        color: def.bg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(def.icon, color: def.fg, size: 20),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.title,
                    style: TextStyle(
                        color: def.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.body,
                    style: TextStyle(
                        color: def.fg.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                fontWeight: FontWeight.w700,
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
    final short = _kShort[agentName] ?? agentName;
    final fg = isInbound ? AppColors.brand : AppColors.accent;
    final bg = isInbound ? AppColors.brandSubtle : AppColors.accentSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.4),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: bg),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg),
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              trace.influenceDescription ??
                  (isInbound
                      ? 'Provided input to this agent'
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
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfacePage,
                    borderRadius: AppSpacing.roundedPill,
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.outline)),
                  ),
                  child: Text(
                    visible ? 'Hide JSON' : 'Show JSON',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                ),
              ],
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
