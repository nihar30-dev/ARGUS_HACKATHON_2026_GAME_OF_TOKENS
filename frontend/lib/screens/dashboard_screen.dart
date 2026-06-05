import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
import '../models/session_response.dart';
import '../services/auth_service.dart';
import '../services/meeting_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scrollCtrl = ScrollController();
  bool _navFrosted = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final frosted = _scrollCtrl.offset > 60;
    if (frosted != _navFrosted) setState(() => _navFrosted = frosted);
  }

  void _goNew() {
    Navigator.pushNamed(context, Routes.newMeeting)
        .then((_) { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<MeetingRepository>(context);
    final meetings = repo.recentMeetings;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Animated aurora hero ──────────────────────────────────
            _HeroSection(onNewMeeting: _goNew),

            // ── Pipeline flow preview ─────────────────────────────────
            const _PipelineSection(),

            // ── Sessions or empty state ───────────────────────────────
            Padding(
              padding: Responsive.pagePadding(context),
              child: Responsive.centered(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    if (meetings.isEmpty)
                      _FadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: _EmptyState(onNewMeeting: _goNew),
                      )
                    else
                      _FadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: _SessionsSection(meetings: meetings),
                      ),
                    const SizedBox(height: AppSpacing.xxxl),
                    _FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: const _FeatureSection(),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = context.watch<ThemeNotifier>();

    // Logo: on dark hero always use dark-bg (white) logo; when frosted use theme
    final logoAsset = (!_navFrosted || isDark)
        ? 'assets/logo/meetwise_logo_dark.svg'
        : 'assets/logo/meetwise_logo.svg';

    // Icon colour: white on hero, theme-appropriate when frosted
    final iconColor = _navFrosted
        ? (isDark ? AppColors.tealLight : AppColors.textSecondary)
        : Colors.white.withValues(alpha: 0.80);

    final auth = context.watch<AuthService>();

    final navRow = SafeArea(
      bottom: false,
      child: SizedBox(
        height: kToolbarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              SvgPicture.asset(logoAsset, height: 26, fit: BoxFit.contain),
              const Spacer(),
              IconButton(
                tooltip: notifier.isDark ? 'Light mode' : 'Dark mode',
                icon: Icon(
                  notifier.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: iconColor, size: 20,
                ),
                onPressed: notifier.toggle,
              ),
              if (auth.isLoggedIn)
                _UserAvatarButton(
                  user: auth.currentUser,
                  iconColor: iconColor,
                  onLogout: () async {
                    final nav = Navigator.of(context);
                    await auth.logout();
                    nav.pushNamedAndRemoveUntil(Routes.login, (_) => false);
                  },
                )
              else
                _NavLoginButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.login),
                  frosted: _navFrosted,
                ),
              const SizedBox(width: 2),
              _NavCTAButton(
                label: 'New Meeting',
                onPressed: _goNew,
                frosted: _navFrosted,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _navFrosted
              ? (isDark
                  ? const Color(0xCC060C1D)
                  : Colors.white.withValues(alpha: 0.88))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: _navFrosted
                  ? (isDark ? AppColors.outlineDark : AppColors.outline)
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
        ),
        // Only apply BackdropFilter when frosted to avoid zero-blur compositor
        // artifacts (white tint) when transparent.
        child: _navFrosted
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: navRow,
                ),
              )
            : navRow,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  final double t1, t2, t3;
  const _AuroraPainter({required this.t1, required this.t2, required this.t3});

  void _drawOrb(Canvas canvas, Size size, double nx, double ny,
      double radius, Color color, double alpha) {
    final center = Offset(size.width * nx, size.height * ny);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrb(canvas, size,
        0.72 + 0.15 * math.sin(t1 * math.pi * 2),
        0.10 + 0.10 * math.cos(t1 * math.pi * 2),
        size.width * 0.40, const Color(0xFF3B82F6), 0.26);

    _drawOrb(canvas, size,
        0.08 + 0.10 * math.cos(t2 * math.pi * 2),
        0.60 + 0.18 * math.sin(t2 * math.pi * 2),
        size.width * 0.44, const Color(0xFF8B5CF6), 0.22);

    _drawOrb(canvas, size,
        0.42 + 0.07 * math.sin(t3 * math.pi * 2 + 1.2),
        0.35 + 0.07 * math.cos(t3 * math.pi * 2),
        size.width * 0.28, const Color(0xFF6366F1), 0.16);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t1 != t1 || old.t2 != t2 || old.t3 != t3;
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = const Color(0x0F3B82F6)
      ..style = PaintingStyle.fill;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FlowDotPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _FlowDotPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;

    // Base line
    canvas.drawLine(
      Offset(0, y), Offset(size.width, y),
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final dotX = size.width * progress;
    final trailStart = math.max(0.0, dotX - 36.0);

    // Trail
    if (dotX > 2) {
      canvas.drawLine(
        Offset(trailStart, y), Offset(dotX, y),
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.transparent, color.withValues(alpha: 0.70)],
          ).createShader(Rect.fromLTWH(trailStart, y - 1, dotX - trailStart, 2))
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dot
    canvas.drawCircle(Offset(dotX, y), 3.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FlowDotPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Fade + slide-up entrance animation.
class _FadeIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  const _FadeIn({required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay.inMilliseconds),
      curve: Curves.easeOut,
      builder: (_, v, inner) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: inner),
      ),
      child: child,
    );
  }
}


/// Gradient-filled primary CTA button.
class _GradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final double fontSize;
  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.fontSize = 15,
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
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: AppSpacing.roundedMd,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: _hovered ? 0.55 : 0.32),
              blurRadius: _hovered ? 32 : 18,
              spreadRadius: _hovered ? 0 : -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppSpacing.roundedMd,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: AppSpacing.roundedMd,
            splashColor: Colors.white.withValues(alpha: 0.14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.smMd),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 17),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(widget.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2)),
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

/// Login button in the nav bar — glass on dark hero, outlined when frosted.
class _NavLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool frosted;
  const _NavLoginButton({required this.onPressed, required this.frosted});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!frosted) {
      // On dark hero: ghost button with white border
      return ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppSpacing.roundedMd,
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppSpacing.roundedMd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.90)),
                    const SizedBox(width: 6),
                    Text('Sign In',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Frosted nav: outlined button with theme-appropriate colours
    final fg = isDark ? AppColors.tealLight : AppColors.brand;
    final borderColor =
        isDark ? AppColors.outlineDark : AppColors.outlineStrong;
    return Container(
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, size: 14, color: fg),
                const SizedBox(width: 6),
                Text('Sign In',
                    style: TextStyle(
                        color: fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nav bar CTA — adapts between glass (on dark hero) and solid (when frosted).
class _NavCTAButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool frosted;
  final bool isDark;
  const _NavCTAButton({
    required this.label, required this.onPressed,
    required this.frosted, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!frosted) {
      // On dark hero: glass button
      return ClipRRect(
        borderRadius: AppSpacing.roundedMd,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: AppSpacing.roundedMd,
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppSpacing.roundedMd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Frosted nav: gradient pill button
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.roundedMd,
          splashColor: Colors.white.withValues(alpha: 0.14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// User avatar button in nav — shows initials, taps to show logout menu.
class _UserAvatarButton extends StatelessWidget {
  final dynamic user; // UserModel | null
  final Color iconColor;
  final VoidCallback onLogout;
  const _UserAvatarButton({
    required this.user, required this.iconColor, required this.onLogout,
  });

  String get _initials {
    final name = user?.name as String? ?? '';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.outlineDark
              : AppColors.outline,
        ),
      ),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceElevatedDark
          : AppColors.surfaceCard,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(_initials,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'email',
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(user?.email ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          onTap: onLogout,
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Sign out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — animated aurora, gradient title, agent strip
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatefulWidget {
  final VoidCallback onNewMeeting;
  const _HeroSection({required this.onNewMeeting});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with TickerProviderStateMixin {
  late final AnimationController _orb1, _orb2, _orb3, _fadeIn;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _orb1  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _orb2  = AnimationController(vsync: this, duration: const Duration(seconds: 13))..repeat(reverse: true);
    _orb3  = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat(reverse: true);
    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fade   = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _orb1.dispose(); _orb2.dispose(); _orb3.dispose(); _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenH  = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: Listenable.merge([_orb1, _orb2, _orb3, _fadeIn]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: screenH * (isMobile ? 0.68 : 0.78)),
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: Stack(
            children: [
              // Aurora orbs
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _AuroraPainter(
                        t1: _orb1.value, t2: _orb2.value, t3: _orb3.value),
                  ),
                ),
              ),
              // Dot grid
              const Positioned.fill(
                child: CustomPaint(painter: _DotGridPainter()),
              ),
              // Bottom fade to scaffold
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_fade),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      child: _HeroContent(onNewMeeting: widget.onNewMeeting),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final VoidCallback onNewMeeting;
  const _HeroContent({required this.onNewMeeting});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final appBarH  = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppSpacing.lg : AppSpacing.xxxl,
        appBarH + (isMobile ? AppSpacing.xxl : AppSpacing.xxxl),
        isMobile ? AppSpacing.lg : AppSpacing.xxxl,
        AppSpacing.xxxl,
      ),
      child: Responsive.centered(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient wordmark
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.brandGradient.createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                'MeetWise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 48 : 72,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                  height: 0.95,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sub-headline
            Text(
              'AI Meeting Intelligence\nPowered by 6 Agents',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: isMobile ? 19 : 26,
                fontWeight: FontWeight.w300,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Description glass pill
            ClipRRect(
              borderRadius: AppSpacing.roundedLg,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    'Each agent reads every prior output, challenges assumptions, and builds on the collective intelligence — producing a meeting strategy no single model could.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: isMobile ? 13 : 14,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // CTA
            _GradientButton(
              onPressed: onNewMeeting,
              icon: Icons.auto_awesome,
              label: 'New Meeting Intelligence',
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Agent pipeline strip
            const _HeroPipelineStrip(),
          ],
        ),
      ),
    );
  }
}

class _HeroPipelineStrip extends StatelessWidget {
  const _HeroPipelineStrip();

  static const _agents = [
    (Icons.person_rounded, 'You', false),
    (Icons.search_rounded, 'Research', true),
    (Icons.person_pin_rounded, 'Persona', false),
    (Icons.lightbulb_rounded, 'Strategy', true),
    (Icons.warning_amber_rounded, 'Objection', true),
    (Icons.fact_check_rounded, 'Critic', false),
    (Icons.summarize_rounded, 'Final', true),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _agents.length; i++) ...[
            _PipelinePill(
              icon: _agents[i].$1,
              label: _agents[i].$2,
              isGemini: _agents[i].$3,
              highlight: i == 0 || i == _agents.length - 1,
            ),
            if (i < _agents.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right_rounded, size: 13,
                    color: Colors.white.withValues(alpha: 0.28)),
              ),
          ],
        ],
      ),
    );
  }
}

class _PipelinePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGemini;
  final bool highlight;
  const _PipelinePill({
    required this.icon, required this.label,
    required this.isGemini, required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGemini ? AppColors.brand : AppColors.ruleBased;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
              color: highlight ? color : Colors.white.withValues(alpha: 0.55)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline section — animated flow diagram
// ─────────────────────────────────────────────────────────────────────────────

class _PipelineSection extends StatefulWidget {
  const _PipelineSection();

  @override
  State<_PipelineSection> createState() => _PipelineSectionState();
}

class _PipelineSectionState extends State<_PipelineSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  static const _nodes = [
    _AgentNode(Icons.search_rounded, 'Research', '1', true, Color(0xFF3B82F6)),
    _AgentNode(Icons.person_pin_rounded, 'Persona', '2', false, Color(0xFF10B981)),
    _AgentNode(Icons.lightbulb_rounded, 'Strategy', '3', true, Color(0xFF3B82F6)),
    _AgentNode(Icons.warning_amber_rounded, 'Objection', '4', true, Color(0xFF6366F1)),
    _AgentNode(Icons.fact_check_rounded, 'Critic', '5', false, Color(0xFF10B981)),
    _AgentNode(Icons.summarize_rounded, 'Final', '6', true, Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF080F1E), const Color(0xFF0B1225)]
              : [const Color(0xFF0F172A), const Color(0xFF1E1B4B)],
        ),
        border: Border(
          top: BorderSide(color: AppColors.brand.withValues(alpha: 0.18)),
          bottom: BorderSide(color: AppColors.brand.withValues(alpha: 0.10)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxxl,
          vertical: AppSpacing.xxxl,
        ),
        child: Responsive.centered(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(
                          color: AppColors.brand.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'HOW IT WORKS',
                      style: TextStyle(
                        color: AppColors.brandMid,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.brandGradient.createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'The 6-Agent Intelligence Pipeline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Each agent reads every prior output — building compounding intelligence.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Pipeline flow
              AnimatedBuilder(
                animation: _flow,
                builder: (context, _) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "You" input node
                        _InputNode(),
                        _buildConnector(0),
                        for (var i = 0; i < _nodes.length; i++) ...[
                          _AgentNodeCard(node: _nodes[i]),
                          if (i < _nodes.length - 1)
                            _buildConnector(i + 1),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Legend row — Wrap prevents overflow on narrow mobile
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LegendChip(
                    color: AppColors.brand,
                    label: 'Gemini AI',
                    icon: Icons.auto_awesome,
                  ),
                  _LegendChip(
                    color: AppColors.ruleBased,
                    label: 'Rule-based',
                    icon: Icons.rule_outlined,
                  ),
                  Text(
                    '· Each agent reads all prior outputs',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(int index) {
    final nodeColor = index == 0
        ? AppColors.brand
        : _nodes[math.min(index - 1, _nodes.length - 1)].color;
    final progress = (_flow.value + index * 0.18) % 1.0;

    return SizedBox(
      width: 56,
      height: 88, // align with node card height
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 56,
          height: 16,
          child: CustomPaint(
            painter: _FlowDotPainter(progress: progress, color: nodeColor),
          ),
        ),
      ),
    );
  }
}

class _AgentNode {
  final IconData icon;
  final String label;
  final String order;
  final bool isGemini;
  final Color color;
  const _AgentNode(this.icon, this.label, this.order, this.isGemini, this.color);
}

class _InputNode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.18), width: 1.5),
          ),
          child: Icon(Icons.person_rounded,
              color: Colors.white.withValues(alpha: 0.70), size: 30),
        ),
        const SizedBox(height: 10),
        Text('You',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: AppSpacing.roundedPill,
          ),
          child: Text('Input',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _AgentNodeCard extends StatelessWidget {
  final _AgentNode node;
  const _AgentNodeCard({required this.node});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glowing circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: node.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: node.color.withValues(alpha: 0.50), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: node.color.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(node.icon, color: node.color, size: 28),
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(node.order,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(node.label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: node.color.withValues(alpha: 0.15),
            borderRadius: AppSpacing.roundedPill,
            border: Border.all(color: node.color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(node.isGemini ? Icons.auto_awesome : Icons.rule_outlined,
                  size: 8, color: node.color),
              const SizedBox(width: 3),
              Text(node.isGemini ? 'Gemini' : 'Rules',
                  style: TextStyle(
                      color: node.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  const _LegendChip({required this.color, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.40)),
          ),
          child: Icon(icon, size: 11, color: color),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sessions section — premium cards from repository only
// ─────────────────────────────────────────────────────────────────────────────

class _SessionsSection extends StatelessWidget {
  final List<SessionResponse> meetings;
  const _SessionsSection({required this.meetings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INTELLIGENCE REPORTS', style: AppTheme.overlineStyle),
                const SizedBox(height: 4),
                Text(
                  'Your meeting strategies',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Latest — featured full-width card
        _FeaturedSessionCard(session: meetings.first),

        // Previous — compact list
        if (meetings.length > 1) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('PREVIOUS', style: AppTheme.overlineStyle),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meetings.length - 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) =>
                _CompactSessionCard(session: meetings[i + 1], delay: i * 60),
          ),
        ],
      ],
    );
  }
}

class _FeaturedSessionCard extends StatelessWidget {
  final SessionResponse session;
  const _FeaturedSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avgConf = session.agentRuns.isEmpty
        ? 0.0
        : session.agentRuns.map((r) => r.confidenceScore).reduce((a, b) => a + b) /
            session.agentRuns.length;
    final totalMs = session.agentRuns.fold<int>(0, (s, r) => s + r.executionMs);
    final confColor = AppColors.forConfidence(avgConf);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkSurfaceGradient
            : AppColors.surfaceGradient,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.brandSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top: org + status + confidence ring
          Padding(
            padding: AppSpacing.cardPaddingLg,
            child: Row(
              children: [
                // Confidence ring
                SizedBox(
                  width: 72, height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0, strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation(
                          (isDark ? Colors.white : AppColors.textPrimary)
                              .withValues(alpha: 0.06),
                        ),
                      ),
                      CircularProgressIndicator(
                        value: avgConf, strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(confColor),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (avgConf * 100).toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900,
                              color: confColor, height: 1.0,
                            ),
                          ),
                          Text('%',
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600,
                              color: confColor.withValues(alpha: 0.7),
                            )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.organizationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          letterSpacing: -0.4, height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (session.stakeholderRole != null) session.stakeholderRole!,
                          if (session.meetingObjective != null) session.meetingObjective!,
                        ].join(' · '),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StatusBadge(status: session.status),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outline),

          // Stats strip
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatChip(
                  value: '${session.agentRuns.length}',
                  label: 'Agents',
                  icon: Icons.smart_toy_outlined,
                  color: AppColors.brand,
                ),
                _StatChip(
                  value: '${session.traces.length}',
                  label: 'Traces',
                  icon: Icons.account_tree_outlined,
                  color: AppColors.accent,
                ),
                _StatChip(
                  value: '${(totalMs / 1000).toStringAsFixed(1)}s',
                  label: 'Runtime',
                  icon: Icons.timer_outlined,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

          // Agent confidence bars
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: session.agentRuns.take(4).map((run) {
                final c = run.confidenceScore;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: Text(run.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: AppColors.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppSpacing.roundedPill,
                          child: LinearProgressIndicator(
                            value: c, minHeight: 5,
                            backgroundColor:
                                AppColors.forConfidence(c).withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.forConfidence(c)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(c * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.forConfidence(c))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (session.agentRuns.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Text('+ ${session.agentRuns.length - 4} more agents',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ),

          // Action buttons
          Padding(
            padding: AppSpacing.cardPaddingLg.copyWith(top: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, Routes.trace, arguments: session),
                    icon: const Icon(Icons.account_tree_outlined, size: 15),
                    label: const Text('View Trace'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, Routes.report, arguments: session),
                    icon: const Icon(Icons.article_outlined, size: 15),
                    label: const Text('Full Report'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
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

class _CompactSessionCard extends StatelessWidget {
  final SessionResponse session;
  final int delay;
  const _CompactSessionCard({required this.session, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final avgConf = session.agentRuns.isEmpty
        ? 0.0
        : session.agentRuns.map((r) => r.confidenceScore).reduce((a, b) => a + b) /
            session.agentRuns.length;
    final confColor = AppColors.forConfidence(avgConf);

    return _FadeIn(
      delay: Duration(milliseconds: delay),
      child: Container(
        decoration: AppTheme.cardDecorationOf(context),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.business_outlined,
                color: AppColors.brand, size: 18),
          ),
          title: Text(session.organizationName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
            session.stakeholderRole ?? session.meetingObjective ?? '',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: confColor.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedPill,
                  border: Border.all(color: confColor.withValues(alpha: 0.30)),
                ),
                child: Text('${(avgConf * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: confColor)),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                onPressed: () => Navigator.pushNamed(
                    context, Routes.trace, arguments: session),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewMeeting;
  const _EmptyState({required this.onNewMeeting});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkSurfaceGradient : AppColors.surfaceGradient,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.brandSubtle,
        ),
      ),
      child: Column(
        children: [
          // Icon with glow ring
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand.withValues(alpha: 0.10),
              border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.brand, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Ready to Transform Your Next Meeting?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Six specialized agents will research your prospect, build stakeholder personas, predict objections, and synthesize a complete meeting strategy.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _GradientButton(
            onPressed: onNewMeeting,
            icon: Icons.auto_awesome,
            label: 'New Meeting Intelligence',
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature section
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  static const _features = [
    _FeatureData(
      icon: Icons.account_tree_outlined,
      color: AppColors.accent,
      title: 'Agent Trace View',
      body: 'Every influence link is recorded — see exactly which agent shaped which output and why. The key differentiator for the hackathon judges.',
    ),
    _FeatureData(
      icon: Icons.fact_check_outlined,
      color: AppColors.warning,
      title: 'Critic Validation',
      body: 'CriticValidatorAgent reviews all prior outputs, flags unsupported claims, and feeds verified corrections directly to FinalSynthesis.',
    ),
    _FeatureData(
      icon: Icons.summarize_outlined,
      color: AppColors.teal,
      title: 'Final Intelligence Brief',
      body: 'A complete, validated meeting strategy: conversation flow, objection playbook, strategic questions, and concrete next steps.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHY MEETWISE', style: AppTheme.overlineStyle),
        const SizedBox(height: 6),
        Text('Built to win the Agent Trace View criteria',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        if (isMobile)
          Column(
            children: _features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _FeatureCard(data: f),
            )).toList(),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _features.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: e.key < _features.length - 1 ? AppSpacing.md : 0),
                child: _FeatureCard(data: e.value),
              ),
            )).toList(),
          ),
      ],
    );
  }
}

class _FeatureData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _FeatureData({
    required this.icon, required this.color,
    required this.title, required this.body,
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: data.color.withValues(alpha: 0.25)),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(data.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  letterSpacing: -0.2)),
          const SizedBox(height: AppSpacing.xs),
          Text(data.body,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.55)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small utility widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status == 'COMPLETED';
    final fg = done ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: fg.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                  color: fg, fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.value, required this.label,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: color, height: 1.0)),
              Text(label,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.60), letterSpacing: 0.2)),
            ],
          ),
        ],
      ),
    );
  }
}
