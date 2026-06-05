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
                          AppSpacing.gapXl,
                          // Workflow preview always shown first — pure visual strip
                          const _FadeSlide(
                            delay: Duration(milliseconds: 60),
                            child: _WorkflowSection(),
                          ),
                          AppSpacing.gapXl,
                          // Meetings section — reads only from repository
                          _FadeSlide(
                            delay: const Duration(milliseconds: 160),
                            child: meetings.isEmpty
                                ? _EmptyState(
                                    onNewMeeting: _goNew,
                                    onRunDemo: _runDemo,
                                  )
                                : _MeetingsSection(
                                    meetings: meetings,
                                    onNewMeeting: _goNew,
                                  ),
                          ),
                          AppSpacing.gapXl,
                          const _FadeSlide(
                            delay: Duration(milliseconds: 260),
                            child: _FeatureRow(),
                          ),
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
          const ThemeToggleButton(),
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
                'Initializing Multi-Agent Pipeline…',
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
}

// ── Fade + slide animation wrapper ───────────────────────────────────────────

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlide({required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 420 + delay.inMilliseconds),
      curve: Curves.easeOut,
      builder: (context, value, inner) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}

// ── Dot grid painter (hero background texture) ────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 30.0;
    final paint = Paint()
      ..color = const Color(0x123B82F6) // 7 % brand blue
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Gradient CTA button ───────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: AppSpacing.roundedMd,
          boxShadow: [
            BoxShadow(
              color: AppColors.glowBrand,
              blurRadius: _hovered ? 28 : 16,
              spreadRadius: _hovered ? 0 : -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppSpacing.roundedMd,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: AppSpacing.roundedMd,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.smMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Base gradient ──────────────────────────────────────────────────
          const Positioned.fill(
            child: DecoratedBox(decoration: AppTheme.heroDecoration),
          ),

          // ── Dot grid texture ───────────────────────────────────────────────
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),

          // ── Blue glow — top right ──────────────────────────────────────────
          Positioned(
            top: -110,
            right: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Violet glow — bottom left ──────────────────────────────────────
          Positioned(
            bottom: -130,
            left: -80,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Indigo glow — centre ──────────────────────────────────────────
          Positioned(
            top: 20,
            left: isMobile ? 80 : 300,
            child: Container(
              width: 320,
              height: 260,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxxl,
              vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxxl,
            ),
            child: Responsive.centered(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hackathon badge
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    builder: (_, v, child) =>
                        Opacity(opacity: v, child: child),
                    child: _HeroBadge(),
                  ),
                  AppSpacing.gapMd,

                  // Title
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOut,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                          offset: Offset(0, 14 * (1 - v)), child: child),
                    ),
                    child: _HeroTitle(isMobile: isMobile),
                  ),
                  AppSpacing.gapLg,

                  // Description
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 580),
                    curve: Curves.easeOut,
                    builder: (_, v, child) =>
                        Opacity(opacity: v, child: child),
                    child: const _HeroDescription(),
                  ),
                  AppSpacing.gapLg,

                  // CTAs
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 680),
                    curve: Curves.easeOut,
                    builder: (_, v, child) =>
                        Opacity(opacity: v, child: child),
                    child: _HeroCTAs(
                      onNewMeeting: onNewMeeting,
                      onViewDemo: onViewDemo,
                    ),
                  ),

                  // Agent count strip
                  AppSpacing.gapXl,
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 780),
                    curve: Curves.easeOut,
                    builder: (_, v, child) =>
                        Opacity(opacity: v, child: child),
                    child: const _HeroAgentStrip(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.tealLight, // violet dot
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Text(
            'ARGUS Hackathon 2026  ·  Multi-Agent AI Platform',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final bool isMobile;
  const _HeroTitle({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient text on "MeetWise"
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.brandGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'MeetWise',
            style: TextStyle(
              color: Colors.white, // masked by ShaderMask
              fontSize: isMobile ? 44 : 58,
              fontWeight: FontWeight.w800,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AI-Powered Meeting Intelligence',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: isMobile ? 17 : 23,
            fontWeight: FontWeight.w300,
            height: 1.3,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _HeroDescription extends StatelessWidget {
  const _HeroDescription();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: const Text(
        '6 specialized agents collaborate in sequence — each agent reads and challenges the outputs of every prior agent — producing a meeting strategy no single model could.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }
}

class _HeroCTAs extends StatelessWidget {
  final VoidCallback onNewMeeting;
  final VoidCallback onViewDemo;
  const _HeroCTAs({required this.onNewMeeting, required this.onViewDemo});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _GradientButton(
          onPressed: onNewMeeting,
          icon: Icons.auto_awesome,
          label: 'New Meeting Intelligence',
        ),
        OutlinedButton.icon(
          onPressed: onViewDemo,
          icon: const Icon(Icons.play_circle_outline, size: 17),
          label: const Text('Run Apollo Hospitals Demo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.smMd),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _HeroAgentStrip extends StatelessWidget {
  const _HeroAgentStrip();

  static const _steps = [
    (Icons.person_rounded, 'You'),
    (Icons.search_rounded, 'Research'),
    (Icons.person_pin_rounded, 'Persona'),
    (Icons.lightbulb_rounded, 'Strategy'),
    (Icons.warning_amber_rounded, 'Objection'),
    (Icons.fact_check_rounded, 'Critic'),
    (Icons.summarize_rounded, 'Final Brief'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            _StepPill(icon: _steps[i].$1, label: _steps[i].$2, isFirst: i == 0, isLast: i == _steps.length - 1),
            if (i < _steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.30)),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFirst;
  final bool isLast;

  const _StepPill({
    required this.icon,
    required this.label,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = isFirst || isLast;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(
          color: highlight
              ? Colors.white.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: highlight
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.65)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workflow section (pure visual preview — no live run data) ─────────────────

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AGENT WORKFLOW', style: AppTheme.overlineStyle),
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
                    Text('AGENT WORKFLOW', style: AppTheme.overlineStyle),
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

        // Idle workflow diagram — runs: null renders all nodes in preview state
        Container(
          decoration: AppTheme.cardDecorationOf(context),
          child: const TraceWorkflowWidget(
            runs: null,
            direction: Axis.horizontal,
          ),
        ),
      ],
    );
  }
}

// ── Meetings section (data from repository only) ──────────────────────────────

class _MeetingsSection extends StatelessWidget {
  final List<SessionResponse> meetings;
  final VoidCallback onNewMeeting;

  const _MeetingsSection({
    required this.meetings,
    required this.onNewMeeting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LATEST MEETING BRIEFING', style: AppTheme.overlineStyle),
        AppSpacing.gapSm,
        _buildMainGrid(context, meetings.first),
        if (meetings.length > 1) ...[
          AppSpacing.gapXl,
          Text('PREVIOUS BRIEFINGS', style: AppTheme.overlineStyle),
          AppSpacing.gapSm,
          _buildPreviousMeetingsList(context, meetings.skip(1).toList()),
        ],
      ],
    );
  }

  Widget _buildMainGrid(BuildContext context, SessionResponse session) {
    final isMobile = Responsive.isMobile(context);
    final cards = [
      Expanded(
        child: _FadeSlide(
          delay: const Duration(milliseconds: 80),
          child: _RecentMeetingCard(session: session),
        ),
      ),
      if (!isMobile) AppSpacing.hGapLg,
      if (isMobile) AppSpacing.gapMd,
      Expanded(
        child: _FadeSlide(
          delay: const Duration(milliseconds: 140),
          child: _AgentStatsCard(session: session),
        ),
      ),
    ];

    return isMobile
        ? Column(children: cards)
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards);
  }

  Widget _buildPreviousMeetingsList(
      BuildContext context, List<SessionResponse> previousMeetings) {
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

        return _FadeSlide(
          delay: Duration(milliseconds: 60 * index),
          child: Container(
            decoration: AppTheme.cardDecorationOf(context),
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
      decoration: AppTheme.cardDecorationOf(context),
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
          Text(
            'No Meeting Strategies Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Generate your first meeting intelligence brief. Six specialized agents will collaborate to analyse your prospect, predict objections, and construct an engagement playbook.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
          AppSpacing.gapLg,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onNewMeeting,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('New Meeting Intelligence'),
              ),
              OutlinedButton.icon(
                onPressed: onRunDemo,
                icon: const Icon(Icons.play_circle_outline, size: 16),
                label: const Text('Try Apollo Hospitals Demo'),
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
      decoration: AppTheme.cardDecorationOf(context),
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
                        if (session.stakeholderRole != null)
                          session.stakeholderRole!,
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
      decoration: AppTheme.cardDecorationOf(context),
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PIPELINE METRICS',
            style: AppTheme.overlineStyle,
          ),
          AppSpacing.gapMd,

          // Stat grid — 2×2
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
      decoration: AppTheme.cardDecorationOf(context),
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
            style:
                TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
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
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
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
              valueColor: AlwaysStoppedAnimation(AppColors.forConfidence(conf)),
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
