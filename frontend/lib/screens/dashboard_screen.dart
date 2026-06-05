import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
import '../models/session_response.dart';
import '../services/mock_meeting_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/info_card.dart';
import '../widgets/trace_workflow_widget.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = MockMeetingService.buildApolloSession();

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(onCta: () => _goNew(context)),
            Padding(
              padding: Responsive.pagePadding(context),
              child: Responsive.centered(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.gapSm,
                    _buildMainGrid(context, session),
                    AppSpacing.gapXl,
                    _WorkflowSection(session: session),
                    AppSpacing.gapXl,
                    _FeatureRow(),
                    AppSpacing.gapXl,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
        title: const AppHeader(),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: () => _goNew(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Meeting'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );

  Widget _buildMainGrid(BuildContext context, SessionResponse session) {
    final isMobile = Responsive.isMobile(context);
    final cards = [
      Expanded(child: _RecentMeetingCard(session: session)),
      if (!isMobile) AppSpacing.hGapLg,
      if (isMobile) AppSpacing.gapMd,
      Expanded(child: _AgentStatsCard(session: session)),
    ];

    return isMobile
        ? Column(children: cards)
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards);
  }

  void _goNew(BuildContext context) =>
      Navigator.pushNamed(context, Routes.newMeeting);
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final VoidCallback onCta;

  const _HeroSection({required this.onCta});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: AppTheme.heroDecoration.copyWith(
        borderRadius: BorderRadius.zero,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxxl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxxl,
      ),
      child: Responsive.centered(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppSpacing.roundedPill,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'ARGUS Hackathon 2026  ·  Multi-Agent AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapMd,

            // Title
            Text(
              'MeetWise',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 40 : 56,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'AI-Powered Multi-Agent\nMeeting Intelligence Platform',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            AppSpacing.gapLg,

            // Sub-text
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedMd,
              ),
              child: Text(
                '6 specialized agents collaborate — each reading and challenging prior outputs — to produce a strategy no single model could.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            AppSpacing.gapLg,

            // CTAs
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: onCta,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate Meeting Intelligence'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.smMd),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onCta,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('View Demo  →  Apollo Hospitals'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.smMd),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent meeting card ───────────────────────────────────────────────────────

class _RecentMeetingCard extends StatelessWidget {
  final SessionResponse session;

  const _RecentMeetingCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final avgConf = session.agentRuns.isEmpty
        ? 0.0
        : session.agentRuns
                .map((r) => r.confidenceScore)
                .reduce((a, b) => a + b) /
            session.agentRuns.length;
    final totalMs =
        session.agentRuns.fold<int>(0, (s, r) => s + r.executionMs);

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.brandSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_outlined,
                    color: AppColors.brand, size: 18),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.organizationName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text('CEO  ·  Partnership Discussion',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StatusBadge(status: session.status),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),

          // Metrics grid
          Row(
            children: [
              _MetricTile(
                value: '${(avgConf * 100).toStringAsFixed(0)}%',
                label: 'Avg Confidence',
                color: AppColors.forConfidence(avgConf),
              ),
              const SizedBox(width: AppSpacing.smMd),
              _MetricTile(
                value: '${session.agentRuns.length}',
                label: 'Agents Run',
                color: AppColors.brand,
              ),
              const SizedBox(width: AppSpacing.smMd),
              _MetricTile(
                value: '${session.traces.length}',
                label: 'Trace Links',
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.smMd),
              _MetricTile(
                value: '${(totalMs / 1000).toStringAsFixed(1)}s',
                label: 'Runtime',
                color: AppColors.textSecondary,
              ),
            ],
          ),

          AppSpacing.gapMd,

          // Confidence bars per agent
          ...session.agentRuns.take(3).map((run) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AgentConfidenceRow(run: run),
              )),
          if (session.agentRuns.length > 3)
            Text(
              '+ ${session.agentRuns.length - 3} more agents',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500),
            ),

          AppSpacing.gapMd,

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                      context, Routes.trace,
                      arguments: session),
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('View Trace'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.smMd),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                      context, Routes.report,
                      arguments: session),
                  icon: const Icon(Icons.article_outlined, size: 16),
                  label: const Text('View Report'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.smMd),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Agent stats card ──────────────────────────────────────────────────────────

class _AgentStatsCard extends StatelessWidget {
  final SessionResponse session;

  const _AgentStatsCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final geminiCount = session.agentRuns.where((r) => r.usedGemini).length;
    final ruleCount = session.agentRuns.length - geminiCount;
    final avgConf = session.agentRuns.isEmpty
        ? 0.0
        : session.agentRuns
                .map((r) => r.confidenceScore)
                .reduce((a, b) => a + b) /
            session.agentRuns.length;

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIPELINE METRICS',
            style: AppTheme.overlineStyle,
          ),
          AppSpacing.gapMd,

          // Big stat grid — 2×2
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  value: '${session.agentRuns.length}',
                  label: 'Total Agents',
                  icon: Icons.smart_toy_outlined,
                  background: AppColors.brandSubtle,
                  foreground: AppColors.brand,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: InfoCard(
                  value: '${session.traces.length}',
                  label: 'Trace Links',
                  icon: Icons.account_tree_outlined,
                  background: AppColors.accentSubtle,
                  foreground: AppColors.accent,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  value: '$geminiCount',
                  label: 'Gemini AI',
                  icon: Icons.auto_awesome,
                  background: AppColors.geminiSurface,
                  foreground: AppColors.gemini,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: InfoCard(
                  value: '$ruleCount',
                  label: 'Rule-Based',
                  icon: Icons.rule_outlined,
                  background: AppColors.ruleBasedSurface,
                  foreground: AppColors.ruleBased,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),

          // Overall readiness bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Readiness',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              Text(
                '${(avgConf * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forConfidence(avgConf),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppSpacing.roundedPill,
            child: LinearProgressIndicator(
              value: avgConf,
              minHeight: 8,
              backgroundColor: AppColors.brandSubtle,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.forConfidence(avgConf)),
            ),
          ),

          AppSpacing.gapMd,

          // Critic validator highlight
          Container(
            padding: AppSpacing.cardPadding,
            decoration: const BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: AppSpacing.roundedMd,
              border: Border.fromBorderSide(
                  BorderSide(color: AppColors.warningSubtle)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fact_check_outlined,
                    color: AppColors.warning, size: 18),
                AppSpacing.hGapSm,
                const Expanded(
                  child: Text(
                    'Critic Validator flagged 1 unsupported claim → FinalSynthesis revised it before delivery.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        height: 1.4,
                        fontWeight: FontWeight.w500),
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

// ── Workflow section ──────────────────────────────────────────────────────────

class _WorkflowSection extends StatelessWidget {
  final SessionResponse session;

  const _WorkflowSection({required this.session});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AGENT WORKFLOW', style: AppTheme.overlineStyle),
              AppSpacing.gapXs,
              Text(
                'Each agent reads all prior outputs — interdependency is the strategy.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              AppSpacing.gapSm,
              const WorkflowLegend(),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AGENT WORKFLOW', style: AppTheme.overlineStyle),
                    AppSpacing.gapXs,
                    Text(
                      'Each agent reads all prior outputs — interdependency is the strategy.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapLg,
              const WorkflowLegend(),
            ],
          ),
        AppSpacing.gapMd,
        Container(
          decoration: AppTheme.cardDecoration,
          child: TraceWorkflowWidget(
            runs: session.agentRuns,
            direction: Axis.horizontal,
          ),
        ),
      ],
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    const features = [
      _FeatureData(
        icon: Icons.account_tree_outlined,
        color: AppColors.accent,
        surface: AppColors.accentSubtle,
        title: 'Agent Trace View',
        body:
            'Every influence link is recorded and visualised — see exactly which agent shaped which output and why.',
      ),
      _FeatureData(
        icon: Icons.fact_check_outlined,
        color: AppColors.warning,
        surface: AppColors.warningLight,
        title: 'Critic Validation',
        body:
            'CriticValidatorAgent reviews all prior outputs, flags unsupported claims, and feeds corrections to FinalSynthesis.',
      ),
      _FeatureData(
        icon: Icons.summarize_outlined,
        color: AppColors.success,
        surface: AppColors.successLight,
        title: 'Final Meeting Brief',
        body:
            'A complete, validated meeting strategy: conversation flow, objection playbook, strategic questions, and next steps.',
      ),
    ];

    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _FeatureCard(data: f),
                ))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((f) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: _FeatureCard(data: f),
                ),
              ))
          .toList(),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final Color color;
  final Color surface;
  final String title;
  final String body;

  const _FeatureData({
    required this.icon,
    required this.color,
    required this.surface,
    required this.title,
    required this.body,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.surface,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          AppSpacing.gapMd,
          Text(
            data.title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          AppSpacing.gapXs,
          Text(
            data.body,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'COMPLETED';
    final fg = isCompleted ? AppColors.success : AppColors.warning;
    final bg = isCompleted ? AppColors.successLight : AppColors.warningLight;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricTile(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


class _AgentConfidenceRow extends StatelessWidget {
  final AgentRun run;

  const _AgentConfidenceRow({required this.run});

  @override
  Widget build(BuildContext context) {
    final conf = run.confidenceScore;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            run.displayName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: ClipRRect(
            borderRadius: AppSpacing.roundedPill,
            child: LinearProgressIndicator(
              value: conf,
              minHeight: 6,
              backgroundColor: AppColors.outline,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.forConfidence(conf)),
            ),
          ),
        ),
        AppSpacing.hGapSm,
        SizedBox(
          width: 36,
          child: Text(
            '${(conf * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.forConfidence(conf)),
          ),
        ),
      ],
    );
  }
}

