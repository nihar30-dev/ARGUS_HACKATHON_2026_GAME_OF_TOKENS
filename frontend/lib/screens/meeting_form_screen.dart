import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
// ApiException is re-exported from meeting_repository.dart — no direct
// api_service.dart import needed in screens.
import '../services/meeting_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/primary_button.dart';

// ── Demo defaults ─────────────────────────────────────────────────────────────

const _kDemoOrg = 'Apollo Hospitals';
const _kDemoRole = 'CEO';
const _kDemoObjective = 'Discuss MEDplat digital health platform partnership';
const _kDemoOffering = 'MEDplat open-source configurable digital health platform';

const _kLoadingSteps = [
  'Researching organization…',
  'Building stakeholder persona…',
  'Crafting engagement strategy…',
  'Predicting objections…',
  'Validating with critic agent…',
  'Synthesizing final report…',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class MeetingFormScreen extends StatefulWidget {
  const MeetingFormScreen({super.key});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _objCtrl = TextEditingController();
  final _offerCtrl = TextEditingController();
  late final TextEditingController _dateCtrl;

  late DateTime _meetingDate;
  bool _loading = false;
  String? _error;
  int _loadingStep = 0;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _meetingDate = DateTime.now().add(const Duration(days: 7));
    _dateCtrl = TextEditingController(text: _formatDate(_meetingDate));
    _prefillDemo();
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _roleCtrl.dispose();
    _objCtrl.dispose();
    _offerCtrl.dispose();
    _dateCtrl.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _prefillDemo() {
    _orgCtrl.text = _kDemoOrg;
    _roleCtrl.text = _kDemoRole;
    _objCtrl.text = _kDemoObjective;
    _offerCtrl.text = _kDemoOffering;
    _setDate(DateTime.now().add(const Duration(days: 7)));
  }

  void _setDate(DateTime d) {
    setState(() {
      _meetingDate = d;
      _dateCtrl.text = _formatDate(d);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) _setDate(picked);
  }

  void _startLoadingAnimation() {
    _loadingStep = 0;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() {
        _loadingStep = (_loadingStep + 1).clamp(0, _kLoadingSteps.length - 1);
      });
    });
  }

  void _stopLoadingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  static String _friendlyError(Object e) {
    if (e is ApiException) {
      if (e.isNetworkError) {
        return 'Cannot connect to the server. '
            'Check your network connection or use the demo below.';
      }
      if (e.isServerError) {
        return 'The server encountered an error. '
            'Please try again, or use "Reset to Demo Values" and submit.';
      }
      if (e.isBadRequest) {
        return 'The server rejected the request. '
            'Please review your inputs and try again.';
      }
      return e.message;
    }
    final raw = e.toString();
    if (raw.startsWith('Exception:')) return raw.substring(10).trim();
    return raw;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _loadingStep = 0;
    });
    _startLoadingAnimation();

    final repo = context.read<MeetingRepository>();
    try {
      final session = await repo.createMeeting(
        organizationName: _orgCtrl.text.trim(),
        meetingObjective: _objCtrl.text.trim(),
        offeringDescription: _offerCtrl.text.trim(),
        stakeholderRole: _roleCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamed(context, Routes.trace, arguments: session);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      _stopLoadingAnimation();
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SingleChildScrollView(
        child: Responsive.centered(
          context,
          Padding(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(),
                AppSpacing.gapLg,
                if (_error != null) ...[
                  ErrorView(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),
                  AppSpacing.gapMd,
                ],
                _buildFormCard(),
                AppSpacing.gapMd,
                _buildActions(),
                AppSpacing.gapXl,
                _buildPipelineSection(),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.brand, size: 18),
            AppSpacing.hGapSm,
            const Text('MeetWise'),
          ],
        ),
      );

  // ── Form card ─────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(label: 'MEETING DETAILS'),
            AppSpacing.gapMd,
            _field(
              ctrl: _orgCtrl,
              label: 'Organization Name',
              hint: 'e.g. Apollo Hospitals',
              icon: Icons.business_outlined,
              maxLength: 100,
            ),
            const SizedBox(height: AppSpacing.smMd),
            // Stakeholder Role + Meeting Date — side by side on wider screens
            Responsive.isMobile(context)
                ? Column(
                    children: [
                      _field(
                        ctrl: _roleCtrl,
                        label: 'Stakeholder Role',
                        hint: 'e.g. CEO, CTO, CFO',
                        icon: Icons.person_outlined,
                        maxLength: 60,
                      ),
                      const SizedBox(height: AppSpacing.smMd),
                      _dateField(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _field(
                          ctrl: _roleCtrl,
                          label: 'Stakeholder Role',
                          hint: 'e.g. CEO, CTO, CFO',
                          icon: Icons.person_outlined,
                          maxLength: 60,
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(child: _dateField()),
                    ],
                  ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
              child: Divider(),
            ),
            const _SectionHeader(label: 'MEETING CONTEXT'),
            AppSpacing.gapMd,
            _field(
              ctrl: _objCtrl,
              label: 'Meeting Objective',
              hint: 'What do you want to achieve in this meeting?',
              icon: Icons.flag_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.smMd),
            _field(
              ctrl: _offerCtrl,
              label: 'Offering / Product Description',
              hint: 'Describe what you are proposing or selling',
              icon: Icons.inventory_2_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int maxLength = 500,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        enabled: !_loading,
        textInputAction:
            maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return '$label is required';
          }
          if (v.trim().length > maxLength) {
            return '$label must be under $maxLength characters';
          }
          return null;
        },
      );

  Widget _dateField() => TextFormField(
        controller: _dateCtrl,
        readOnly: true,
        enabled: !_loading,
        onTap: _pickDate,
        decoration: const InputDecoration(
          labelText: 'Meeting Date',
          prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: Icon(Icons.arrow_drop_down, size: 22),
        ),
      );

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    final step = _loadingStep.clamp(0, _kLoadingSteps.length - 1);
    final stepLabel = _kLoadingSteps[step];

    return Column(
      children: [
        PrimaryButton(
          label: 'Generate Meeting Intelligence',
          loadingLabel: stepLabel,
          icon: Icons.auto_awesome,
          onPressed: _submit,
          loading: _loading,
          verticalPadding: AppSpacing.md,
        ),
        AppSpacing.gapSm,
        PrimaryButton(
          outlined: true,
          label: 'Reset to Demo Values',
          icon: Icons.refresh_outlined,
          onPressed: _loading ? null : _prefillDemo,
        ),
      ],
    );
  }

  // ── Pipeline section ──────────────────────────────────────────────────────

  Widget _buildPipelineSection() {
    const agents = [
      _AgentInfo('1', 'Organization Research', Icons.search_outlined, true),
      _AgentInfo('2', 'Stakeholder Persona', Icons.person_outlined, false),
      _AgentInfo('3', 'Engagement Strategy', Icons.lightbulb_outlined, true),
      _AgentInfo('4', 'Objection Prediction', Icons.warning_amber_outlined, true),
      _AgentInfo('5', 'Critic Validator', Icons.fact_check_outlined, false),
      _AgentInfo('6', 'Final Synthesis', Icons.summarize_outlined, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          label: 'AGENT PIPELINE',
          description:
              'Each agent reads all prior outputs. Their interdependency is the strategy.',
        ),
        AppSpacing.gapMd,
        for (var i = 0; i < agents.length; i++)
          _AgentTimelineRow(info: agents[i], isLast: i == agents.length - 1),
        AppSpacing.gapMd,
        const Row(
          children: [
            _TypeLegend(
              dot: AppColors.geminiSurface,
              border: AppColors.gemini,
              label: 'Gemini AI',
              text: AppColors.gemini,
            ),
            SizedBox(width: AppSpacing.md),
            _TypeLegend(
              dot: AppColors.ruleBasedSurface,
              border: AppColors.ruleBased,
              label: 'Rule-based',
              text: AppColors.ruleBased,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Reusable private widgets ──────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingLg,
      decoration: AppTheme.brandSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: AppSpacing.roundedPill,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'ARGUS Hackathon 2026',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'Meeting Intelligence',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          AppSpacing.gapXs,
          const Text(
            'Six specialized agents collaborate — each reading and challenging prior outputs — to produce a meeting strategy no single agent could.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? description;

  const _SectionHeader({required this.label, this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.overlineStyle),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            description!,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AgentInfo {
  final String order;
  final String name;
  final IconData icon;
  final bool isGemini;

  const _AgentInfo(this.order, this.name, this.icon, this.isGemini);
}

class _AgentTimelineRow extends StatelessWidget {
  final _AgentInfo info;
  final bool isLast;

  const _AgentTimelineRow({required this.info, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final fg = info.isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = info.isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: fg, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  info.order,
                  style: TextStyle(
                      color: fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: AppColors.outline),
                ),
            ],
          ),
          AppSpacing.hGapMd,
          // Row content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.smMd, top: 4),
              child: Row(
                children: [
                  Icon(info.icon, size: 15, color: fg),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      info.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(
                      info.isGemini ? 'Gemini' : 'Rule-based',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: fg),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────

class _TypeLegend extends StatelessWidget {
  final Color dot;
  final Color border;
  final String label;
  final Color text;

  const _TypeLegend({
    required this.dot,
    required this.border,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dot,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: text),
        ),
      ],
    );
  }
}
