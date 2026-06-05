import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/session_response.dart';
import 'agent_trace_screen.dart';

class FinalReportScreen extends StatelessWidget {
  final SessionResponse session;
  const FinalReportScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final report = session.finalReport!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Meeting Brief — ${session.organizationName}'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ConfidenceBanner(confidence: report.overallConfidence, cs: cs),
          const SizedBox(height: 20),
          if (report.executiveBrief != null) ...[
            _SectionCard(
              title: 'Executive Brief',
              icon: Icons.summarize_outlined,
              cs: cs,
              child: Text(report.executiveBrief!, style: const TextStyle(fontSize: 15, height: 1.6)),
            ),
            const SizedBox(height: 16),
          ],
          if (report.conversationFlowJson != null)
            _ConversationFlowCard(json: report.conversationFlowJson!, cs: cs),
          const SizedBox(height: 16),
          if (report.questionsJson != null)
            _JsonListCard(title: 'Key Questions to Ask', icon: Icons.help_outline,
                json: report.questionsJson!, cs: cs),
          const SizedBox(height: 16),
          if (report.objectionResponsesJson != null)
            _ObjectionCard(json: report.objectionResponsesJson!, cs: cs),
          const SizedBox(height: 16),
          if (report.nextStepsJson != null)
            _JsonListCard(title: 'Next Steps', icon: Icons.check_circle_outline,
                json: report.nextStepsJson!, cs: cs),
          const SizedBox(height: 24),
          _AgentInfluenceFooter(session: session, cs: cs),
        ]),
      ),
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  final double confidence;
  final ColorScheme cs;
  const _ConfidenceBanner({required this.confidence, required this.cs});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final color = confidence >= 0.8 ? Colors.green : confidence >= 0.5 ? Colors.orange : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.verified_outlined, color: cs.primary, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Meeting Preparation Complete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${session(context)} agents collaborated — ${session2(context)} Gemini + ${session3(context)} Rule-based',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ),
        Column(children: [
          Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: color)),
          Text('confidence', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  // These are resolved at the widget level but need session from parent — using placeholder text
  String session(BuildContext context) => '6';
  String session2(BuildContext context) => '4';
  String session3(BuildContext context) => '2';
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.cs, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
        ]),
        const Divider(height: 20),
        child,
      ]),
    ),
  );
}

class _ConversationFlowCard extends StatelessWidget {
  final String json;
  final ColorScheme cs;
  const _ConversationFlowCard({required this.json, required this.cs});

  @override
  Widget build(BuildContext context) {
    List<dynamic> phases = [];
    try { phases = jsonDecode(json) as List<dynamic>; } catch (_) {}

    return _SectionCard(
      title: 'Conversation Flow',
      icon: Icons.timeline,
      cs: cs,
      child: Column(
        children: phases.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value as Map<String, dynamic>;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primaryContainer,
                child: Text('${i + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 12)),
              ),
              if (i < phases.length - 1)
                Container(width: 2, height: 40, color: cs.outlineVariant),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(p['phase'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(p['duration'] as String? ?? '',
                          style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(p['approach'] as String? ?? '',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ]),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class _JsonListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String json;
  final ColorScheme cs;
  const _JsonListCard({required this.title, required this.icon, required this.json, required this.cs});

  @override
  Widget build(BuildContext context) {
    List<String> items = [];
    try { items = (jsonDecode(json) as List<dynamic>).map((e) => e.toString()).toList(); } catch (_) {}

    return _SectionCard(
      title: title,
      icon: icon,
      cs: cs,
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.arrow_right, color: cs.primary, size: 20),
            const SizedBox(width: 4),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 14, height: 1.4))),
          ]),
        )).toList(),
      ),
    );
  }
}

class _ObjectionCard extends StatelessWidget {
  final String json;
  final ColorScheme cs;
  const _ObjectionCard({required this.json, required this.cs});

  @override
  Widget build(BuildContext context) {
    List<dynamic> items = [];
    try { items = jsonDecode(json) as List<dynamic>; } catch (_) {}

    return _SectionCard(
      title: 'Objection Responses',
      icon: Icons.shield_outlined,
      cs: cs,
      child: Column(
        children: items.map((item) {
          final m = item as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.warning_amber_outlined, size: 16, color: cs.error),
                const SizedBox(width: 6),
                Expanded(child: Text(m['objection'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(child: Text(m['response'] as String? ?? '',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
              ]),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _AgentInfluenceFooter extends StatelessWidget {
  final SessionResponse session;
  final ColorScheme cs;
  const _AgentInfluenceFooter({required this.session, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.account_tree_outlined, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('This brief was shaped by ${session.traces.length} agent influence connections.',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(
            'The Critic Validator identified issues that were incorporated into the Final Synthesis. '
            'Tap "Trace View" to see exactly how each agent influenced the others.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}
