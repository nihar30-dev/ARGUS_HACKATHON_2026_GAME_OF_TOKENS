import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/meeting_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class PastMeetingsScreen extends StatefulWidget {
  const PastMeetingsScreen({super.key});

  @override
  State<PastMeetingsScreen> createState() => _PastMeetingsScreenState();
}

class _PastMeetingsScreenState extends State<PastMeetingsScreen> {
  late Future<List<UserMeeting>> _future;

  @override
  void initState() {
    super.initState();
    _future = Provider.of<AuthService>(context, listen: false).getMyMeetings();
  }

  void _reload() {
    setState(() {
      _future =
          Provider.of<AuthService>(context, listen: false).getMyMeetings();
    });
  }

  Future<void> _openMeeting(BuildContext context, String meetingId) async {
    final repo       = Provider.of<MeetingRepository>(context, listen: false);
    final nav        = Navigator.of(context);
    final messenger  = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final session = await repo.getMeeting(meetingId);
      if (!mounted) return;
      nav.pop();
      nav.pushNamed(Routes.trace, arguments: session);
    } catch (e) {
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not load meeting: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppHeader(),
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        child: Responsive.centered(
          context,
          Padding(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapLg,
                Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: AppColors.brand, size: 22),
                    AppSpacing.hGapSm,
                    const Text(
                      'My Past Meetings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _reload,
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                const Text(
                  'All meeting briefings generated while signed in to your account.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                AppSpacing.gapLg,
                FutureBuilder<List<UserMeeting>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        message: snap.error.toString(),
                        onRetry: _reload,
                      );
                    }
                    final meetings = snap.data ?? [];
                    if (meetings.isEmpty) {
                      return const _EmptyState();
                    }
                    return _MeetingList(
                      meetings: meetings,
                      onTap: (id) => _openMeeting(context, id),
                    );
                  },
                ),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Meeting list ──────────────────────────────────────────────────────────────

class _MeetingList extends StatelessWidget {
  final List<UserMeeting> meetings;
  final void Function(String meetingId) onTap;

  const _MeetingList({required this.meetings, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meetings.length,
      separatorBuilder: (_, __) => AppSpacing.gapSm,
      itemBuilder: (_, i) => _MeetingCard(
        meeting: meetings[i],
        onTap: () => onTap(meetings[i].meetingRequestId),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final UserMeeting meeting;
  final VoidCallback onTap;

  const _MeetingCard({required this.meeting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final conf    = meeting.overallConfidence ?? 0.0;
    final isReady = meeting.status == 'COMPLETED';
    final date    = meeting.createdAt;

    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.brandSubtle,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.business_outlined,
              color: AppColors.brand, size: 20),
        ),
        title: Text(
          meeting.organizationName,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              [
                if (meeting.stakeholderRole != null) meeting.stakeholderRole!,
                if (meeting.meetingObjective != null)
                  meeting.meetingObjective!,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            if (date != null) ...[
              const SizedBox(height: 3),
              Text(
                _formatDate(date),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReady) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.forConfidenceSurface(conf),
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  '${(conf * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forConfidence(conf),
                  ),
                ),
              ),
              AppSpacing.hGapSm,
            ] else ...[
              _StatusChip(status: meeting.status),
              AppSpacing.hGapSm,
            ],
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
        onTap: isReady ? onTap : null,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isRunning = status == 'RUNNING';
    final fg = isRunning ? AppColors.warning : AppColors.textMuted;
    final bg = isRunning ? AppColors.warningLight : AppColors.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedPill,
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: AppTheme.cardDecorationOf(context),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.brandSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                color: AppColors.brand, size: 28),
          ),
          AppSpacing.gapMd,
          const Text(
            'No meetings yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Meetings you run while signed in will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          AppSpacing.gapLg,
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, Routes.home),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Start a Meeting'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: AppSpacing.roundedLg,
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.dangerSubtle)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 32),
          AppSpacing.gapSm,
          Text(
            message.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.danger, fontSize: 13, height: 1.4),
          ),
          AppSpacing.gapMd,
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
