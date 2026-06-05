import 'package:flutter/material.dart';
import '../models/session_response.dart';
import 'agent_trace_screen.dart';
import 'final_report_screen.dart';

class AgentDashboardScreen extends StatelessWidget {
  final SessionResponse session;

  const AgentDashboardScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.organizationName),
        backgroundColor: cs.surface,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AgentTraceScreen(session: session),
            )),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Trace View'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SessionSummaryBar(session: session),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: session.agentRuns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _AgentRunCard(run: session.agentRuns[i]),
            ),
          ),
          if (session.finalReport != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FinalReportScreen(session: session),
                  )),
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('View Final Meeting Brief'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionSummaryBar extends StatelessWidget {
  final SessionResponse session;
  const _SessionSummaryBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avgConf = session.agentRuns.isEmpty ? 0.0
        : session.agentRuns.map((r) => r.confidenceScore).reduce((a, b) => a + b)
            / session.agentRuns.length;
    final geminiCount = session.agentRuns.where((r) => r.usedGemini).length;
    final totalMs = session.agentRuns.fold<int>(0, (s, r) => s + r.executionMs);

    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${session.agentRuns.length}', 'Agents Run', cs),
          _stat('${(avgConf * 100).toStringAsFixed(0)}%', 'Avg Confidence', cs),
          _stat('$geminiCount Gemini', '${session.agentRuns.length - geminiCount} Rules', cs),
          _stat('${(totalMs / 1000).toStringAsFixed(1)}s', 'Total Time', cs),
          _stat('${session.traces.length}', 'Trace Links', cs),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, ColorScheme cs) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer, fontSize: 16)),
      Text(label, style: TextStyle(color: cs.onPrimaryContainer, fontSize: 11)),
    ],
  );
}

class _AgentRunCard extends StatefulWidget {
  final AgentRun run;
  const _AgentRunCard({required this.run});

  @override
  State<_AgentRunCard> createState() => _AgentRunCardState();
}

class _AgentRunCardState extends State<_AgentRunCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final run = widget.run;
    final confColor = run.confidenceScore >= 0.8
        ? Colors.green
        : run.confidenceScore >= 0.5
            ? Colors.orange
            : Colors.red;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: run.usedGemini ? cs.primaryContainer : cs.tertiaryContainer,
                  child: Text('${run.executionOrderIndex}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: run.usedGemini ? cs.primary : cs.tertiary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(run.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(run.usedGemini ? Icons.auto_awesome : Icons.rule,
                          size: 12,
                          color: run.usedGemini ? cs.primary : cs.tertiary),
                      const SizedBox(width: 4),
                      Text(run.usedGemini ? 'Gemini AI' : 'Rule-based',
                          style: TextStyle(fontSize: 11,
                              color: run.usedGemini ? cs.primary : cs.tertiary)),
                      const SizedBox(width: 12),
                      Icon(Icons.timer_outlined, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${run.executionMs}ms',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ]),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${(run.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: confColor, fontSize: 18)),
                  Text('confidence', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant),
              ]),
              if (run.influencedBy.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: run.influencedBy.map((name) {
                  final short = name.replaceAll('Agent', '');
                  return Chip(
                    label: Text('← $short', style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: cs.secondaryContainer,
                  );
                }).toList()),
              ],
              if (_expanded) ...[
                const Divider(height: 24),
                Text('Output', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    run.outputJson,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
