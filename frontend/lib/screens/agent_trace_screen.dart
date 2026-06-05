import 'package:flutter/material.dart';
import '../models/session_response.dart';

class AgentTraceScreen extends StatefulWidget {
  final SessionResponse session;
  const AgentTraceScreen({super.key, required this.session});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  String? _selectedAgent;

  static const List<String> _pipeline = [
    'OrganizationResearchAgent',
    'StakeholderPersonaAgent',
    'EngagementStrategyAgent',
    'ObjectionPredictionAgent',
    'CriticValidatorAgent',
    'FinalSynthesisAgent',
  ];

  static const Map<String, String> _shortName = {
    'OrganizationResearchAgent': 'Research',
    'StakeholderPersonaAgent': 'Persona',
    'EngagementStrategyAgent': 'Strategy',
    'ObjectionPredictionAgent': 'Objections',
    'CriticValidatorAgent': 'Critic',
    'FinalSynthesisAgent': 'Synthesis',
  };

  static const Map<String, bool> _usesGemini = {
    'OrganizationResearchAgent': true,
    'StakeholderPersonaAgent': false,
    'EngagementStrategyAgent': true,
    'ObjectionPredictionAgent': true,
    'CriticValidatorAgent': false,
    'FinalSynthesisAgent': true,
  };

  AgentRun? _runFor(String name) =>
      widget.session.agentRuns.where((r) => r.agentName == name).firstOrNull;

  List<AgentTrace> _tracesFrom(String source) =>
      widget.session.traces.where((t) => t.sourceAgent == source).toList();

  List<AgentTrace> _tracesTo(String target) =>
      widget.session.traces.where((t) => t.targetAgent == target).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Agent Trace — ${widget.session.organizationName}'),
        backgroundColor: cs.surface,
      ),
      body: Column(
        children: [
          _buildLegend(cs),
          Expanded(
            child: Row(
              children: [
                _buildPipelineColumn(cs),
                const VerticalDivider(width: 1),
                Expanded(child: _buildDetailPanel(cs)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Agent Trace View', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          _legendChip(cs.primaryContainer, cs.primary, Icons.auto_awesome, 'Gemini AI'),
          const SizedBox(width: 8),
          _legendChip(cs.tertiaryContainer, cs.tertiary, Icons.rule, 'Rule-based'),
          const SizedBox(width: 16),
          Icon(Icons.arrow_forward, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('influenced', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _legendChip(Color bg, Color fg, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: fg)),
      ]),
    );
  }

  Widget _buildPipelineColumn(ColorScheme cs) {
    return SizedBox(
      width: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _pipeline.length,
        itemBuilder: (ctx, i) {
          final name = _pipeline[i];
          final run = _runFor(name);
          final isSelected = _selectedAgent == name;
          final inboundCount = _tracesTo(name).length;
          final outboundCount = _tracesFrom(name).length;
          final gemini = _usesGemini[name] ?? false;

          return GestureDetector(
            onTap: () => setState(() => _selectedAgent = isSelected ? null : name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primaryContainer
                    : gemini ? cs.primaryContainer.withValues(alpha: 0.4) : cs.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: cs.primary, width: 2)
                    : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${i + 1}.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(width: 4),
                  Icon(gemini ? Icons.auto_awesome : Icons.rule,
                      size: 12, color: gemini ? cs.primary : cs.tertiary),
                ]),
                const SizedBox(height: 4),
                Text(_shortName[name] ?? name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                if (run != null)
                  LinearProgressIndicator(
                    value: run.confidenceScore,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: run.confidenceScore >= 0.8
                        ? Colors.green
                        : run.confidenceScore >= 0.5 ? Colors.orange : Colors.red,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                const SizedBox(height: 4),
                Row(children: [
                  if (inboundCount > 0) ...[
                    Icon(Icons.arrow_downward, size: 10, color: cs.onSurfaceVariant),
                    Text(' $inboundCount in', style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 4),
                  ],
                  if (outboundCount > 0) ...[
                    Icon(Icons.arrow_upward, size: 10, color: cs.primary),
                    Text(' $outboundCount out', style: TextStyle(fontSize: 9, color: cs.primary)),
                  ],
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailPanel(ColorScheme cs) {
    if (_selectedAgent == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.touch_app_outlined, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Select an agent to see its trace',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          _buildInfluenceMatrix(cs),
        ]),
      );
    }

    final name = _selectedAgent!;
    final run = _runFor(name);
    final inbound = _tracesTo(name);
    final outbound = _tracesFrom(name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_usesGemini[name] == true ? Icons.auto_awesome : Icons.rule,
              color: cs.primary),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        if (run != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            _badge('Order: ${run.executionOrderIndex}', cs.secondaryContainer, cs.onSecondaryContainer),
            const SizedBox(width: 8),
            _badge('${(run.confidenceScore * 100).toStringAsFixed(0)}% confidence',
                run.confidenceScore >= 0.8
                    ? Colors.green.shade100
                    : run.confidenceScore >= 0.5 ? Colors.orange.shade100 : Colors.red.shade100,
                Colors.black87),
            const SizedBox(width: 8),
            _badge('${run.executionMs}ms', cs.surfaceContainerHighest, cs.onSurfaceVariant),
            const SizedBox(width: 8),
            _badge(run.usedGemini ? 'Gemini' : 'Rule-based',
                run.usedGemini ? cs.primaryContainer : cs.tertiaryContainer,
                run.usedGemini ? cs.primary : cs.tertiary),
          ]),
        ],
        if (inbound.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Inputs From', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          ...inbound.map((t) => _traceCard(t, isInbound: true, cs: cs)),
        ],
        if (outbound.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Influenced', style: TextStyle(fontWeight: FontWeight.w600, color: cs.tertiary)),
          const SizedBox(height: 8),
          ...outbound.map((t) => _traceCard(t, isInbound: false, cs: cs)),
        ],
        if (run != null) ...[
          const SizedBox(height: 20),
          Text('Raw Output', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
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
      ]),
    );
  }

  Widget _traceCard(AgentTrace trace, {required bool isInbound, required ColorScheme cs}) {
    final agentName = isInbound ? trace.sourceAgent : trace.targetAgent;
    final shortName = _shortName[agentName] ?? agentName;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isInbound ? cs.primaryContainer.withValues(alpha: 0.3) : cs.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(isInbound ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: isInbound ? cs.primary : cs.tertiary),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shortName,
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: isInbound ? cs.primary : cs.tertiary)),
            if (trace.influenceDescription != null) ...[
              const SizedBox(height: 4),
              Text(trace.influenceDescription!,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ])),
        ]),
      ),
    );
  }

  Widget _buildInfluenceMatrix(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Influence Summary',
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          ...widget.session.traces.take(6).map((t) {
            final from = _shortName[t.sourceAgent] ?? t.sourceAgent;
            final to = _shortName[t.targetAgent] ?? t.targetAgent;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Chip(
                  label: Text(from, style: const TextStyle(fontSize: 11)),
                  backgroundColor: cs.primaryContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 14, color: cs.onSurfaceVariant),
                ),
                Chip(
                  label: Text(to, style: const TextStyle(fontSize: 11)),
                  backgroundColor: cs.secondaryContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
  );
}
