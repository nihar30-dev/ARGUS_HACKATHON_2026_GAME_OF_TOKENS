import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'agent_dashboard_screen.dart';

class MeetingInputScreen extends StatefulWidget {
  const MeetingInputScreen({super.key});

  @override
  State<MeetingInputScreen> createState() => _MeetingInputScreenState();
}

class _MeetingInputScreenState extends State<MeetingInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController();
  final _objCtrl = TextEditingController();
  final _offerCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _orgCtrl.dispose();
    _objCtrl.dispose();
    _offerCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({bool demo = false}) async {
    if (!demo && !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final api = context.read<ApiService>();
    try {
      final session = demo
          ? await api.runDemo()
          : await api.createMeeting(
              organizationName: _orgCtrl.text.trim(),
              meetingObjective: _objCtrl.text.trim(),
              offeringDescription: _offerCtrl.text.trim(),
              stakeholderRole: _roleCtrl.text.trim(),
            );

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AgentDashboardScreen(session: session),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeetWise'),
        backgroundColor: cs.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prepare Your Meeting',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    )),
            const SizedBox(height: 6),
            Text('Six AI agents collaborate to prepare your optimal strategy.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_orgCtrl, 'Organization Name', 'e.g. Apollo Hospitals',
                      Icons.business),
                  const SizedBox(height: 16),
                  _field(_roleCtrl, 'Stakeholder Role', 'e.g. CTO, CFO, CEO',
                      Icons.person),
                  const SizedBox(height: 16),
                  _field(_objCtrl, 'Meeting Objective',
                      'e.g. Pitch our AI workflow automation platform',
                      Icons.flag, maxLines: 3),
                  const SizedBox(height: 16),
                  _field(_offerCtrl, 'Our Offering / Product Description',
                      'What are you selling or proposing?',
                      Icons.inventory, maxLines: 4),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : () => _submit(),
                icon: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Running 6 Agents...' : 'Prepare Meeting Strategy'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _submit(demo: true),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Run Demo (Apollo Hospitals)'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 32),
            _agentPipelinePreview(cs),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _agentPipelinePreview(ColorScheme cs) {
    final agents = [
      ('1', 'Research', Icons.search, true),
      ('2', 'Persona', Icons.person_outline, false),
      ('3', 'Strategy', Icons.lightbulb_outline, true),
      ('4', 'Objections', Icons.warning_amber_outlined, true),
      ('5', 'Critic', Icons.fact_check_outlined, false),
      ('6', 'Synthesis', Icons.summarize_outlined, true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agent Pipeline',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: agents.map((a) {
            return Chip(
              avatar: Icon(a.$3, size: 16, color: a.$4 ? cs.primary : cs.tertiary),
              label: Text('${a.$1}. ${a.$2}',
                  style: TextStyle(fontSize: 12, color: a.$4 ? cs.primary : cs.tertiary)),
              backgroundColor: a.$4 ? cs.primaryContainer : cs.tertiaryContainer,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _legend(cs.primary, cs.primaryContainer, 'Gemini AI'),
          const SizedBox(width: 16),
          _legend(cs.tertiary, cs.tertiaryContainer, 'Rule-based'),
        ]),
      ],
    );
  }

  Widget _legend(Color fg, Color bg, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: bg, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: fg)),
    ],
  );
}
