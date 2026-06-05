import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
import '../models/session_response.dart';
import '../services/meeting_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/info_card.dart';
import '../widgets/trace_workflow_widget.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loadingDemo = false;

  // Static preview runs for the workflow section when there is no active session data.
  // This shows the 6-agent sequential flow in a clean, educational way.
  late final List<AgentRun> _previewRuns;

  @override
  void initState() {
    super.initState();
    _previewRuns = [
      AgentRun(
        agentName: 'OrganizationResearchAgent',
        executionOrderIndex: 1,
        confidenceScore: 0.92,
        influencedBy: [],
        usedGemini: true,
        executionMs: 2400,
        outputJson: '',
      ),
      AgentRun(
        agentName: 'StakeholderPersonaAgent',
        executionOrderIndex: 2,
        confidenceScore: 0.88,
        influencedBy: ['OrganizationResearchAgent'],
        usedGemini: false,
        executionMs: 150,
        outputJson: '',
      ),
      AgentRun(
        agentName: 'EngagementStrategyAgent',
        executionOrderIndex: 3,
        confidenceScore: 0.85,
        influencedBy: ['OrganizationResearchAgent', 'StakeholderPersonaAgent'],
        usedGemini: true,
        executionMs: 3100,
        outputJson: '',
      ),
      AgentRun(
        agentName: 'ObjectionPredictionAgent',
        executionOrderIndex: 4,
        confidenceScore: 0.80,
        influencedBy: [
          'OrganizationResearchAgent',
          'StakeholderPersonaAgent',
          'EngagementStrategyAgent'
        ],
        usedGemini: true,
        executionMs: 2800,
        outputJson: '',
      ),
      AgentRun(
        agentName: 'CriticValidatorAgent',
        executionOrderIndex: 5,
        confidenceScore: 0.95,
        influencedBy: [
          'OrganizationResearchAgent',
          'StakeholderPersonaAgent',
          'EngagementStrategyAgent',
          'ObjectionPredictionAgent'
        ],
        usedGemini: false,
        executionMs: 180,
        outputJson: '',
      ),
      AgentRun(
        agentName: 'FinalSynthesisAgent',
        executionOrderIndex: 6,
        confidenceScore: 0.90,
        influencedBy: [
          'OrganizationResearchAgent',
          'StakeholderPersonaAgent',
          'EngagementStrategyAgent',
          'ObjectionPredictionAgent',
          'CriticValidatorAgent'
        ],
        usedGemini: true,
        executionMs: 3500,
        outputJson: '',
      ),
    ];
  }

  Future<void> _runDemo() async {
    setState(() => _loadingDemo = true);
    try {
      final repo = Provider.of<MeetingRepository>(context, listen: false);
      if (MeetingRepository.useMockData) {
        final session = await repo.runDemo();
        if (!mounted) return;
        Navigator.pushNamed(context, Routes.trace, arguments: session)
            .then((_) { if (mounted) setState(() {}); });
      } else {
        final start = await repo.startDemo();
        if (!mounted) return;
        Navigator.pushNamed(context, Routes.live, arguments: start)
            .then((_) { if (mounted) setState(() {}); });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error running demo: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingDemo = false);
    }
  }

  void _goNew() {
    Navigator.pushNamed(context, Routes.newMeeting).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<MeetingRepository>(context);
    final meetings = repo.recentMeetings;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _loadingDemo
          ? _buildDemoLoading()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroSection(
                    onNewMeeting: _goNew,
                    onViewDemo: _runDemo,
                  ),
                  Padding(
                    padding: Responsive.pagePadding(context),
                    child: Responsive.centered(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSpacing.gapLg,
                          if (meetings.isEmpty)
                            _EmptyState(onNewMeeting: _goNew, onRunDemo: _runDemo)
                          else ...[
                            Text(
                              'LATEST MEETING BRIEFING',
                              style: AppTheme.overlineStyle,
                            ),
                            AppSpacing.gapSm,
                            _buildMainGrid(context, meetings.first),
                            if (meetings.length > 1) ...[
                              AppSpacing.gapXl,
                              Text(
                                'PREVIOUS BRIEFINGS',
                                style: AppTheme.overlineStyle,
                              ),
                              AppSpacing.gapSm,
                              _buildPreviousMeetingsList(meetings.skip(1).toList()),
                            ],
                          ],
                          AppSpacing.gapXl,
                          _WorkflowSection(runs: _previewRuns),
                          AppSpacing.gapXl,
                          const _FeatureRow(),
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
              onPressed: _goNew,
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

  Widget _buildDemoLoading() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppTheme.heroDecoration.copyWith(borderRadius: BorderRadius.zero),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4.5,
                ),
              ),
              AppSpacing.gapLg,
              const Text(
                'Initializing Multi-Agent Pipeline...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                'Orchestrating 6 specialized agents for Apollo Hospitals demo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainGrid(BuildContext context, SessionResponse session) {
    final isMobile = Responsive.isMobile(context);
    final cards = [
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: child,
            ),
          ),
          child: _RecentMeetingCard(session: session),
        ),
      ),
      if (!isMobile) AppSpacing.hGapLg,
      if (isMobile) AppSpacing.gapMd,
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: child,
            ),
          ),
          child: _AgentStatsCard(session: session),
        ),
      ),
    ];

    return isMobile
        ? Column(children: cards)
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards);
  }

  Widget _buildPreviousMeetingsList(List<SessionResponse> previousMeetings) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previousMeetings.length,
      separatorBuilder: (_, __) => AppSpacing.gapSm,
      itemBuilder: (context, index) {
        final session = previousMeetings[index];
        final avgConf = session.agentRuns.isEmpty
            ? 0.0
            : session.agentRuns
                    .map((r) => r.confidenceScore)
                    .reduce((a, b) => a + b) /
                session.agentRuns.length;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            decoration: AppTheme.cardDecoration,
            child: ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.brandSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_outlined,
                    color: AppColors.brand, size: 16),
              ),
              title: Text(
                session.organizationName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if (session.stakeholderRole != null) session.stakeholderRole!,
                  if (session.meetingObjective != null) session.meetingObjective!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.forConfidenceSurface(avgConf),
                      borderRadius: AppSpacing.roundedPill,
                    ),
                    child: Text(
                      '${(avgConf * 100).toStringAsFixed(0)}% Match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forConfidence(avgConf),
                      ),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.trace,
                      arguments: session,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final VoidCallback onNewMeeting;
  final VoidCallback onViewDemo;

  const _HeroSection({
    required this.onNewMeeting,
    required this.onViewDemo,
  });

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
            const Text(
              'MeetWise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
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
              child: const Text(
                '6 specialized agents collaborate — each reading and challenging prior outputs — to produce a strategy no single model could.',
                style: TextStyle(
                  color: Colors.white,
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
                  onPressed: onNewMeeting,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('New Meeting Intelligence'),
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
                  onPressed: onViewDemo,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Run Demo (Apollo Hospitals)'),
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

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewMeeting;
  final VoidCallback onRunDemo;

  const _EmptyState({
    required this.onNewMeeting,
    required this.onRunDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.brandLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.brand,
              size: 30,
            ),
          ),
          AppSpacing.gapMd,
          const Text(
            'No Meeting Strategy Generated Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Generate your first meeting intelligence brief. Six specialized agents will collaborate to analyze your prospect, predict objections, and construct an engagement playbook.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          AppSpacing.gapLg,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: onNewMeeting,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Prepare Meeting Strategy'),
              ),
              OutlinedButton.icon(
                onPressed: onRunDemo,
                icon: const Icon(Icons.play_circle_outline, size: 16),
                label: const Text('Try Sample Demo'),
              ),
            ],
          ),
        ],
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
                    Text(
                      [
                        if (session.stakeholderRole != null) session.stakeholderRole!,
                        'Briefing Session',
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
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
              const SizedBox(width: AppSpacing.sm),
              _MetricTile(
                value: '${session.agentRuns.length}',
                label: 'Agents Run',
                color: AppColors.brand,
              ),
              const SizedBox(width: AppSpacing.sm),
              _MetricTile(
                value: '${session.traces.length}',
                label: 'Trace Links',
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
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
                  fontSize: 11,
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
                    'Critic Validator checks all prior outputs, flags unsupported claims, and ensures Final Synthesis is fully validated.',
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
  final List<AgentRun> runs;

  const _WorkflowSection({required this.runs});

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
            runs: runs,
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
                  fontSize: 18,
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
