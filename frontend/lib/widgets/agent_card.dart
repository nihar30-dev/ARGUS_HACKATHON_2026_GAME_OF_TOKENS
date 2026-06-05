import 'package:flutter/material.dart';
import '../models/session_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// ── Agent type badge ──────────────────────────────────────────────────────────

/// Gemini AI / Rule-based pill badge.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFg = isGemini ? AppColors.gemini : AppColors.ruleBased;
    final activeBg = isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    final idleFg   = isDark ? const Color(0xFF64748B) : AppColors.textMuted;
    final idleBg   = isDark ? AppColors.surfaceCodeDark : AppColors.surfacePage;

    final fg = active ? activeFg : idleFg;
    final bg = active ? activeBg : idleBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGemini ? Icons.auto_awesome : Icons.rule_outlined,
            size: 10,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.xxs + 1),
          Text(
            isGemini ? 'Gemini AI' : 'Rule-based',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agent card ────────────────────────────────────────────────────────────────

/// Compact horizontal card showing a single agent's order, name, type, and
/// confidence score. Fully dark-mode aware.
class AgentCard extends StatelessWidget {
  final AgentRun run;
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
    final conf        = run.confidenceScore;
    final typeFg      = run.usedGemini ? AppColors.gemini  : AppColors.ruleBased;
    final typeBg      = run.usedGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final outlineColor = isDark ? AppColors.outlineDark     : AppColors.outline;
    final borderColor  = active ? typeFg : outlineColor;
    final borderWidth  = active ? 2.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadowXs,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Order bubble ───────────────────────────────────────────────
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: typeBg,
                shape: BoxShape.circle,
                border: Border.all(color: typeFg, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${run.executionOrderIndex}',
                style: TextStyle(
                  color: typeFg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppSpacing.hGapMd,
            // ── Name + badge ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AgentTypeBadge(isGemini: run.usedGemini),
                ],
              ),
            ),
            // ── Confidence ─────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(conf * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forConfidence(conf),
                  ),
                ),
                const SizedBox(height: 3),
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
