import 'package:flutter/material.dart';
import '../models/pipeline_message.dart';
import '../models/session_response.dart';
import '../screens/dashboard_screen.dart';
import '../screens/meeting_form_screen.dart';
import '../screens/agent_dashboard_screen.dart';
import '../screens/agent_trace_screen.dart';
import '../screens/final_report_screen.dart';
import '../screens/pipeline_live_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/error_view.dart';

class Routes {
  static const String home       = '/';
  static const String newMeeting = '/new';
  static const String live       = '/live';
  static const String dashboard  = '/dashboard';
  static const String trace      = '/trace';
  static const String report     = '/report';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case newMeeting:
        return MaterialPageRoute(builder: (_) => const MeetingFormScreen());
      case live:
        final args = settings.arguments;
        if (args is! MeetingStartResponse) return _badArgRoute(settings.name);
        return MaterialPageRoute(
            builder: (_) => PipelineLiveScreen(start: args));
      case dashboard:
        final session = _sessionArg(settings);
        if (session == null) return _badArgRoute(settings.name);
        return MaterialPageRoute(
            builder: (_) => AgentDashboardScreen(session: session));
      case trace:
        final session = _sessionArg(settings);
        if (session == null) return _badArgRoute(settings.name);
        return MaterialPageRoute(
            builder: (_) => AgentTraceScreen(session: session));
      case report:
        final session = _sessionArg(settings);
        if (session == null) return _badArgRoute(settings.name);
        return MaterialPageRoute(
            builder: (_) => FinalReportScreen(session: session));
      default:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Returns the route argument as [SessionResponse], or null if missing/wrong type.
  static SessionResponse? _sessionArg(RouteSettings s) {
    final args = s.arguments;
    return args is SessionResponse ? args : null;
  }

  /// A route that shows a friendly error when navigation arguments are missing.
  static Route<dynamic> _badArgRoute(String? routeName) =>
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Navigation Error')),
          body: ErrorView(
            compact: false,
            title: 'Missing Session Data',
            message:
                'Could not open "${routeName ?? 'this page'}" — '
                'no meeting session was provided.\n\n'
                'Return to the home screen and start a new meeting.',
            onRetry: () => Navigator.pushNamedAndRemoveUntil(
                ctx, Routes.home, (_) => false),
            retryLabel: 'Go to Home',
          ),
        ),
      );
}

// ── App-level error boundary ──────────────────────────────────────────────────

/// Wraps any widget tree so unhandled Flutter errors are shown as a message
/// instead of a red crash screen. Attach to [MaterialApp.builder].
class AppErrorBoundary extends StatelessWidget {
  final Widget? child;
  final FlutterErrorDetails? errorDetails;

  const AppErrorBoundary({super.key, this.child, this.errorDetails});

  @override
  Widget build(BuildContext context) {
    if (errorDetails != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 48),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'An unexpected error occurred. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child ?? const SizedBox.shrink();
  }
}
