import 'package:flutter/material.dart';

import '../models/session_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'agent_card.dart';

// ── Node definitions ──────────────────────────────────────────────────────────

enum _Kind { input, gemini, ruleBased, output }

class _Node {
  final String agentName; // '' for User/Brief pseudo-nodes
  final int order; // 0 for pseudo-nodes
  final String label;
  final IconData icon;
  final _Kind kind;

  const _Node({
    required this.agentName,
    required this.order,
    required this.label,
    required this.icon,
    required this.kind,
  });
}

const List<_Node> _kNodes = [
  _Node(agentName: '', order: 0, label: 'You', icon: Icons.person_rounded, kind: _Kind.input),
  _Node(agentName: 'OrganizationResearchAgent', order: 1, label: 'Research', icon: Icons.search_rounded, kind: _Kind.gemini),
  _Node(agentName: 'StakeholderPersonaAgent', order: 2, label: 'Persona', icon: Icons.person_pin_rounded, kind: _Kind.ruleBased),
  _Node(agentName: 'EngagementStrategyAgent', order: 3, label: 'Strategy', icon: Icons.lightbulb_rounded, kind: _Kind.gemini),
  _Node(agentName: 'ObjectionPredictionAgent', order: 4, label: 'Objection', icon: Icons.warning_amber_rounded, kind: _Kind.gemini),
  _Node(agentName: 'CriticValidatorAgent', order: 5, label: 'Critic', icon: Icons.fact_check_rounded, kind: _Kind.ruleBased),
  _Node(agentName: 'FinalSynthesisAgent', order: 6, label: 'Final', icon: Icons.summarize_rounded, kind: _Kind.gemini),
  _Node(agentName: '', order: 0, label: 'Brief', icon: Icons.article_rounded, kind: _Kind.output),
];

// ── Colors per kind and state ─────────────────────────────────────────────────

Color _fg(_Kind k) {
  switch (k) {
    case _Kind.input:
      return AppColors.textSecondary;
    case _Kind.gemini:
      return AppColors.gemini;
    case _Kind.ruleBased:
      return AppColors.ruleBased;
    case _Kind.output:
      return AppColors.textOnBrand;
  }
}

Color _bg(_Kind k) {
  switch (k) {
    case _Kind.input:
      return AppColors.surfacePage;
    case _Kind.gemini:
      return AppColors.geminiSurface;
    case _Kind.ruleBased:
      return AppColors.ruleBasedSurface;
    case _Kind.output:
      return AppColors.brand;
  }
}

Color _border(_Kind k) {
  switch (k) {
    case _Kind.input:
      return AppColors.outline;
    case _Kind.gemini:
      return AppColors.brand;
    case _Kind.ruleBased:
      return AppColors.ruleBased;
    case _Kind.output:
      return AppColors.brandDark;
  }
}

// ── Public widget ─────────────────────────────────────────────────────────────

/// Pipeline visualization: User → Research → Persona → Strategy →
/// Objection → Critic → Final → Brief.
///
/// [direction]:
///   [Axis.horizontal] — scrollable left-to-right row.
///     Used on the Dashboard workflow section.
///   [Axis.vertical] — top-to-bottom column with full-width node cards.
///     Used on the Trace View pipeline strip.
///
/// [runs] — live [AgentRun] list from a [SessionResponse]. When null every
/// agent renders in idle state (grey, no confidence shown).
///
/// [activeAgentName] — highlights one node (selected agent on trace screen).
///
/// [onAgentTap] — fires when a node is tapped; pass the agent name.
///
/// [compact] — reduces node size; suitable for header strips.
class TraceWorkflowWidget extends StatelessWidget {
  final List<AgentRun>? runs;
  final String? activeAgentName;
  final void Function(String agentName)? onAgentTap;
  final Axis direction;
  final bool compact;

  const TraceWorkflowWidget({
    super.key,
    this.runs,
    this.activeAgentName,
    this.onAgentTap,
    this.direction = Axis.horizontal,
    this.compact = false,
  });

  AgentRun? _runFor(_Node node) {
    if (node.agentName.isEmpty || runs == null) return null;
    return runs!
        .cast<AgentRun?>()
        .firstWhere((r) => r?.agentName == node.agentName, orElse: () => null);
  }

  bool _isActive(_Node node) =>
      node.agentName.isNotEmpty && node.agentName == activeAgentName;

  bool _isCompleted(_Node node) => _runFor(node) != null;

  @override
  Widget build(BuildContext context) {
    return direction == Axis.horizontal
        ? _buildHorizontal(context)
        : _buildVertical(context);
  }

  // ── Horizontal layout ──────────────────────────────────────────────────────

  Widget _buildHorizontal(BuildContext context) {
    final nodeSize = compact ? 40.0 : 56.0;
    final fontSize = compact ? 10.0 : 11.0;
    final confSize = compact ? 9.0 : 10.0;
    final nodeWidth = compact ? 64.0 : 84.0;
    final arrowPad = compact ? 2.0 : 6.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
        vertical: compact ? AppSpacing.sm : AppSpacing.mdLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _kNodes.length; i++) ...[
            _HorizNode(
              node: _kNodes[i],
              run: _runFor(_kNodes[i]),
              isActive: _isActive(_kNodes[i]),
              isCompleted: _isCompleted(_kNodes[i]),
              nodeSize: nodeSize,
              nodeWidth: nodeWidth,
              fontSize: fontSize,
              confSize: confSize,
              onTap: _kNodes[i].agentName.isNotEmpty && onAgentTap != null
                  ? () => onAgentTap!(_kNodes[i].agentName)
                  : null,
            ),
            if (i < _kNodes.length - 1)
              Padding(
                padding: EdgeInsets.only(
                    bottom: compact ? AppSpacing.sm : AppSpacing.mdLg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: arrowPad),
                    Icon(Icons.arrow_forward_rounded,
                        size: compact ? 14 : 18,
                        color: AppColors.textMuted),
                    SizedBox(width: arrowPad),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Vertical layout ────────────────────────────────────────────────────────

  Widget _buildVertical(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _kNodes.length; i++) ...[
            _VertNode(
              node: _kNodes[i],
              run: _runFor(_kNodes[i]),
              isActive: _isActive(_kNodes[i]),
              isCompleted: _isCompleted(_kNodes[i]),
              onTap: _kNodes[i].agentName.isNotEmpty && onAgentTap != null
                  ? () => onAgentTap!(_kNodes[i].agentName)
                  : null,
            ),
            if (i < _kNodes.length - 1) _VertArrow(nextKind: _kNodes[i + 1].kind),
          ],
        ],
      ),
    );
  }
}

// ── Horizontal node ───────────────────────────────────────────────────────────

class _HorizNode extends StatelessWidget {
  final _Node node;
  final AgentRun? run;
  final bool isActive;
  final bool isCompleted;
  final double nodeSize;
  final double nodeWidth;
  final double fontSize;
  final double confSize;
  final VoidCallback? onTap;

  const _HorizNode({
    required this.node,
    required this.run,
    required this.isActive,
    required this.isCompleted,
    required this.nodeSize,
    required this.nodeWidth,
    required this.fontSize,
    required this.confSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fg(node.kind);
    final bg = _bg(node.kind);
    final border = _border(node.kind);

    final idleFg = AppColors.textMuted;
    final idleBg = AppColors.surfacePage;
    final idleBorder = AppColors.outline;

    final effectiveFg = (isCompleted || node.kind == _Kind.input || node.kind == _Kind.output) ? fg : idleFg;
    final effectiveBg = (isCompleted || node.kind == _Kind.input || node.kind == _Kind.output) ? bg : idleBg;
    final effectiveBorder = (isCompleted || node.kind == _Kind.input || node.kind == _Kind.output) ? border : idleBorder;

    final conf = run?.confidenceScore;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: nodeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle with optional glow for active
            Container(
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                color: effectiveBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? effectiveBorder : effectiveBorder.withValues(alpha: 0.8),
                  width: isActive ? 2.5 : 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: effectiveBorder.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : (node.kind == _Kind.output && isCompleted)
                        ? [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(node.icon, color: effectiveFg, size: nodeSize * 0.38),
                  if (node.order > 0)
                    Positioned(
                      bottom: nodeSize * 0.07,
                      right: nodeSize * 0.07,
                      child: Container(
                        width: nodeSize * 0.28,
                        height: nodeSize * 0.28,
                        decoration: BoxDecoration(
                          color: isCompleted ? effectiveBorder : idleBorder,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${node.order}',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: nodeSize * 0.14,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            // Label
            Text(
              node.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? effectiveFg
                    : isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
              ),
            ),
            // Confidence score
            if (conf != null) ...[
              const SizedBox(height: 2),
              Text(
                '${(conf * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: confSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forConfidence(conf)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Vertical node ─────────────────────────────────────────────────────────────

class _VertNode extends StatelessWidget {
  final _Node node;
  final AgentRun? run;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _VertNode({
    required this.node,
    required this.run,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fg(node.kind);
    final bg = _bg(node.kind);
    final border = _border(node.kind);

    final isReal = node.kind != _Kind.input && node.kind != _Kind.output;
    final effectiveFg = (isCompleted || !isReal) ? fg : AppColors.textMuted;
    final effectiveBg = (isCompleted || !isReal) ? bg : AppColors.surfacePage;
    final effectiveBorder = (isCompleted || !isReal) ? border : AppColors.outline;

    final conf = run?.confidenceScore;
    final ms = run?.executionMs;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.smMd),
        decoration: BoxDecoration(
          color: isActive ? effectiveBg : AppColors.surfaceCard,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isActive ? effectiveBorder : AppColors.outline,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveBg,
                shape: BoxShape.circle,
                border: Border.all(color: effectiveBorder, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(node.icon, color: effectiveFg, size: 16),
                  if (node.order > 0)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isCompleted ? effectiveBorder : AppColors.outline,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${node.order}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            // Label + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? effectiveFg : AppColors.textPrimary,
                    ),
                  ),
                  if (isReal) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AgentTypeBadge(
                            isGemini: node.kind == _Kind.gemini,
                            active: isCompleted),
                        if (ms != null) ...[
                          AppSpacing.hGapSm,
                          Text(
                            '${ms}ms',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Confidence on the right
            if (conf != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(conf * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forConfidence(conf)),
                  ),
                  const Text('conf',
                      style:
                          TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
              AppSpacing.hGapSm,
              // Compact confidence bar
              SizedBox(
                width: 48,
                child: ClipRRect(
                  borderRadius: AppSpacing.roundedPill,
                  child: LinearProgressIndicator(
                    value: conf,
                    minHeight: 5,
                    backgroundColor:
                        AppColors.forConfidenceSubtle(conf),
                    valueColor: AlwaysStoppedAnimation(
                        AppColors.forConfidence(conf)),
                  ),
                ),
              ),
            ] else if (isReal && !isCompleted) ...[
              const Text(
                'Pending',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VertArrow extends StatelessWidget {
  final _Kind nextKind;

  const _VertArrow({required this.nextKind});

  @override
  Widget build(BuildContext context) {
    final isKey = nextKind == _Kind.ruleBased; // Critic is rule-based
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 8,
            color: AppColors.outline,
          ),
          Icon(Icons.arrow_downward_rounded,
              size: 14,
              color: isKey ? AppColors.warning : AppColors.textMuted),
          Container(
            width: 2,
            height: 8,
            color: AppColors.outline,
          ),
        ],
      ),
    );
  }
}

// ── Legend (optional companion widget) ───────────────────────────────────────

/// Two-dot legend: Gemini AI · Rule-based.
/// Drop next to the workflow section header.
class WorkflowLegend extends StatelessWidget {
  const WorkflowLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(
          dot: AppColors.geminiSurface,
          ring: AppColors.gemini,
          label: 'Gemini AI',
          fg: AppColors.gemini,
        ),
        SizedBox(width: AppSpacing.md),
        _LegendDot(
          dot: AppColors.ruleBasedSurface,
          ring: AppColors.ruleBased,
          label: 'Rule-based',
          fg: AppColors.ruleBased,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color dot;
  final Color ring;
  final String label;
  final Color fg;

  const _LegendDot(
      {required this.dot,
      required this.ring,
      required this.label,
      required this.fg});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                border: Border.all(color: ring)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: fg)),
        ],
      );
}
