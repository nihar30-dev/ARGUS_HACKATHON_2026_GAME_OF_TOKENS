import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/responsive.dart';
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

const _kAgentNames = [
  'Organization Research Agent',
  'Stakeholder Persona Agent',
  'Engagement Strategy Agent',
  'Objection Prediction Agent',
  'Critic Validator Agent',
  'Final Synthesis Agent',
];

const _kLoadingDescriptions = [
  'Analyzing hospital history, EMR vendors (Tasy/McKesson), and regional footprint...',
  'Constructing detailed profile for CEO: focus on clinical APIs and interoperability...',
  'Framing MEDplat positioning as a unification layer, not vendor replacement...',
  'Anticipating pushback on integration timeline and HL7 FHIR compliance...',
  'Checking strategy and objection plays for compliance and claims validation...',
  'Synthesizing final executive briefing document and strategic playbook...',
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
    // Kept empty by default to look like a premium clean SaaS product,
    // but the user can easily pre-fill using the demo button.
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
    setState(() {
      _orgCtrl.text = _kDemoOrg;
      _roleCtrl.text = _kDemoRole;
      _objCtrl.text = _kDemoObjective;
      _offerCtrl.text = _kDemoOffering;
      _setDate(DateTime.now().add(const Duration(days: 7)));
    });
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
    final isMock = MeetingRepository.useMockData;
    // Walk through steps quickly in mock mode so user sees the progress,
    // otherwise take more time to match real backend LLM pipeline execution.
    final stepDuration = isMock ? const Duration(milliseconds: 350) : const Duration(milliseconds: 4500);

    _loadingTimer = Timer.periodic(stepDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_loadingStep < _kAgentNames.length - 1) {
          _loadingStep++;
        }
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
        return 'Cannot connect to the server. Check your network or make sure the Spring Boot backend is running.';
      }
      if (e.isServerError) {
        return 'The server encountered an error while orchestrating agents. Please try again.';
      }
      return e.message;
    }
    return e.toString();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _loadingStep = 0; });

    final repo = context.read<MeetingRepository>();

    if (MeetingRepository.useMockData) {
      // Mock mode: keep old blocking + animated overlay behaviour
      _startLoadingAnimation();
      try {
        final session = await repo.createMeeting(
          organizationName: _orgCtrl.text.trim(),
          meetingObjective: _objCtrl.text.trim(),
          offeringDescription: _offerCtrl.text.trim(),
          stakeholderRole: _roleCtrl.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.trace, arguments: session);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = _friendlyError(e));
      } finally {
        _stopLoadingAnimation();
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Real backend: POST returns immediately → navigate to live pipeline screen
      try {
        final start = await repo.startMeeting(
          organizationName: _orgCtrl.text.trim(),
          meetingObjective: _objCtrl.text.trim(),
          offeringDescription: _offerCtrl.text.trim(),
          stakeholderRole: _roleCtrl.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.live, arguments: start);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = _friendlyError(e));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Responsive.centered(
              context,
              Padding(
                padding: Responsive.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroBanner(onPrefillDemo: _prefillDemo),
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
                    _buildPipelinePreview(),
                    AppSpacing.gapXl,
                  ],
                ),
              ),
            ),
          ),
          if (_loading) _buildLoadingOverlay(),
        ],
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
              hint: 'Who are you meeting with? (e.g. Apollo Hospitals)',
              icon: Icons.business_outlined,
              maxLength: 100,
            ),
            const SizedBox(height: AppSpacing.smMd),
            Responsive.isMobile(context)
                ? Column(
                    children: [
                      _field(
                        ctrl: _roleCtrl,
                        label: 'Stakeholder Role',
                        hint: 'Who is the decision maker? (e.g. CEO, CTO)',
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
                          hint: 'Who is the decision maker? (e.g. CEO, CTO)',
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
              hint: 'What do you want to achieve? (e.g. Pitch integration platform)',
              icon: Icons.flag_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.smMd),
            _field(
              ctrl: _offerCtrl,
              label: 'Offering / Product Description',
              hint: 'Describe your product or proposed partnership details...',
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
    return Column(
      children: [
        PrimaryButton(
          label: 'Generate Meeting Intelligence',
          icon: Icons.auto_awesome,
          onPressed: _submit,
          loading: _loading,
          verticalPadding: AppSpacing.md,
        ),
      ],
    );
  }

  // ── Pipeline Preview ──────────────────────────────────────────────────────

  Widget _buildPipelinePreview() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            label: 'COLLABORATIVE PIPELINE WORKFLOW',
            description:
                'Six specialized AI and rule-based agents run sequentially. Each agent builds upon and validates prior answers to construct an airtight briefing strategy.',
          ),
          AppSpacing.gapLg,
          for (var i = 0; i < _kAgentNames.length; i++)
            _PreviewStepperRow(
              index: i + 1,
              name: _kAgentNames[i],
              isLast: i == _kAgentNames.length - 1,
              isGemini: i != 1 && i != 4, // 2 and 5 are rule-based
            ),
        ],
      ),
    );
  }

  // ── Animated Loading Overlay ──────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    final activeAgentName = _kAgentNames[_loadingStep];
    final activeDescription = _kLoadingDescriptions[_loadingStep];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) => Container(
        color: Colors.black.withValues(alpha: 0.65 * value),
        width: double.infinity,
        height: double.infinity,
        child: child,
      ),
      child: Center(
        child: Container(
          width: 480,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppSpacing.roundedLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.cardPaddingLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: AppColors.brand,
                    ),
                  ),
                  AppSpacing.gapLg,
                  const Text(
                    'Multi-Agent Pipeline Executing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Currently Running: $activeAgentName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.cardPadding,
                    decoration: AppTheme.brandSurface,
                    child: Text(
                      activeDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  const Divider(),
                  AppSpacing.gapMd,
                  // Active Progress Stepper List
                  Column(
                    children: List.generate(_kAgentNames.length, (index) {
                      final name = _kAgentNames[index];
                      final isCompleted = index < _loadingStep;
                      final isActive = index == _loadingStep;

                      Color itemColor = AppColors.textMuted;
                      Widget leadingWidget = Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outline, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                      );

                      if (isCompleted) {
                        itemColor = AppColors.success;
                        leadingWidget = const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        );
                      } else if (isActive) {
                        itemColor = AppColors.brand;
                        leadingWidget = const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brand,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            leadingWidget,
                            AppSpacing.hGapMd,
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: itemColor,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSubtle,
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                                child: const Text(
                                  'RUNNING',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
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

// ── Reusable private widgets ──────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final VoidCallback onPrefillDemo;

  const _HeroBanner({required this.onPrefillDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingLg,
      decoration: AppTheme.brandSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              TextButton.icon(
                onPressed: onPrefillDemo,
                icon: const Icon(Icons.refresh_outlined, size: 14),
                label: const Text(
                  'Fill with Demo Values',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          const Text(
            'Meeting Strategy Generator',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          AppSpacing.gapXs,
          const Text(
            'Provide the target organization and details below. Six cooperative agents will build, Objection-proof, and validate a customized strategy.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.55),
          ),
        ],
      ),
    );
  }
}

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
                color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _PreviewStepperRow extends StatelessWidget {
  final int index;
  final String name;
  final bool isLast;
  final bool isGemini;

  const _PreviewStepperRow({
    required this.index,
    required this.name,
    required this.isLast,
    required this.isGemini,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isGemini ? AppColors.gemini : AppColors.ruleBased;
    final bg = isGemini ? AppColors.geminiSurface : AppColors.ruleBasedSurface;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: fg, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.outline,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md, top: 2),
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(color: fg.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      isGemini ? 'Gemini AI' : 'Rule-based',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
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
