import 'package:flutter/material.dart';
import '../models/session_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// ── Agent type badge ──────────────────────────────────────────────────────────

/// Gemini AI / Rule-based pill badge.
///
/// [active] — when false the badge renders in a dimmed idle state (used by
/// [TraceWorkflowWidget] for agents that have not yet run).
///
/// Replaces the private `_TypeBadge` in `agent_trace_screen.dart` and
/// `_TypeTag` in `trace_workflow_widget.dart`.
class AgentTypeBadge extends StatelessWidget {
  final bool isGemini;
  final bool active;

  const AgentTypeBadge({
    super.key,
    required this.isGemini,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeFg = isGemini ? AppColors.gemini : AppColors.ruleBased;
    final activeBg =
        isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    final fg = active ? activeFg : AppColors.textMuted;
    final bg = active ? activeBg : AppColors.surfacePage;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AppSpacing.roundedPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGemini ? Icons.auto_awesome : Icons.rule_outlined,
            size: 10,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            isGemini ? 'Gemini AI' : 'Rule-based',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

// ── Agent card ────────────────────────────────────────────────────────────────

/// Compact horizontal card showing a single agent's order, name, type, and
/// confidence score.
///
/// Use in agent overview lists or dashboard summaries.
class AgentCard extends StatelessWidget {
  final AgentRun run;

  /// Highlights the card with a colored border when true.
  final bool active;
  final VoidCallback? onTap;

  const AgentCard({
    super.key,
    required this.run,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final conf = run.confidenceScore;
    final fg = run.usedGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg =
        run.usedGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    final borderColor =
        active ? fg : AppColors.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: borderColor, width: active ? 2 : 1),
        ),
        child: Row(
          children: [
            // Order bubble
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: fg, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${run.executionOrderIndex}',
                style: TextStyle(
                    color: fg, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            AppSpacing.hGapMd,
            // Name + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  AgentTypeBadge(isGemini: run.usedGemini),
                ],
              ),
            ),
            // Confidence
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
                ClipRRect(
                  borderRadius: AppSpacing.roundedPill,
                  child: SizedBox(
                    width: 48,
                    child: LinearProgressIndicator(
                      value: conf,
                      minHeight: 4,
                      backgroundColor: AppColors.forConfidenceSubtle(conf),
                      valueColor: AlwaysStoppedAnimation(
                          AppColors.forConfidence(conf)),
                    ),
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
