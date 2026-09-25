import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../schemes/presentation/providers/schemes_providers.dart';
import '../../domain/profile_models.dart';
import '../providers/profile_providers.dart';

/// One question the schemes may ask. Answered once here, kept on the profile, and reused by
/// every eligibility check.
class DetailQuestion {
  const DetailQuestion.yesNo(this.key, this.title, {this.hint}) : options = null, multi = false;
  const DetailQuestion.choice(this.key, this.title, this.options, {this.hint}) : multi = false;
  const DetailQuestion.multi(this.key, this.title, this.options, {this.hint}) : multi = true;

  final String key;
  final String title;
  final String? hint;

  /// value -> label. Null for a yes/no question.
  final Map<String, String>? options;
  final bool multi;
}

class DetailGroup {
  const DetailGroup(this.title, this.icon, this.questions);

  final String title;
  final IconData icon;
  final List<DetailQuestion> questions;
}

const cropChoices = {
  'Soybean': 'Soybean',
  'Cotton': 'Cotton',
  'Tur': 'Tur (pigeon pea)',
  'Wheat': 'Wheat',
  'Jowar': 'Jowar',
  'Bajra': 'Bajra',
  'Gram': 'Gram (chana)',
  'Sugarcane': 'Sugarcane',
  'Onion': 'Onion',
  'Grapes': 'Grapes',
  'Pomegranate': 'Pomegranate',
  'Vegetables': 'Vegetables',
};

/// The questions, grouped. Keys match the server (`src/data/farmerDetails.js`).
const detailGroups = [
  DetailGroup('About you', Icons.person_outline, [
    DetailQuestion.choice('category', 'Your social category', {'general': 'General', 'obc': 'OBC', 'sc': 'SC', 'st': 'ST'}, hint: 'Some schemes give a higher subsidy to SC/ST farmers'),
    DetailQuestion.choice('gender', 'Gender', {'male': 'Male', 'female': 'Female', 'other': 'Other'}, hint: 'Women farmers get extra benefit in several schemes'),
  ]),
  DetailGroup('Your land', Icons.terrain_outlined, [
    DetailQuestion.choice('landOwnership', 'How do you hold your land?', {'owner': 'I own it', 'tenant': 'Tenant', 'sharecropper': 'Sharecropper', 'none': 'No land'}),
    DetailQuestion.yesNo('nameInLandRecords', 'Is your name in the land records (7/12 extract)?'),
    DetailQuestion.choice('irrigation', 'Main source of water', {'rainfed': 'Rain only', 'well': 'Well', 'borewell': 'Borewell', 'canal': 'Canal', 'drip': 'Drip', 'sprinkler': 'Sprinkler'}),
    DetailQuestion.multi('primaryCrops', 'Crops you grow', cropChoices),
    DetailQuestion.yesNo('practisesOrganic', 'Do you farm organically?'),
    DetailQuestion.yesNo('inFarmerGroup', 'Are you part of a farmer group?', hint: 'A group of 5 or more farmers can join PGS-India organic certification together'),
  ]),
  DetailGroup('Bank and credit', Icons.account_balance_outlined, [
    DetailQuestion.yesNo('hasAadhaar', 'Do you have an Aadhaar card?'),
    DetailQuestion.yesNo('hasBankAccount', 'Do you have a savings bank account?'),
    DetailQuestion.yesNo('hasKcc', 'Do you have a Kisan Credit Card?'),
    DetailQuestion.yesNo('hasCropLoan', 'Do you have a crop loan this season?', hint: 'Crop insurance is compulsory for loan farmers'),
  ]),
  DetailGroup('Equipment and family', Icons.handyman_outlined, [
    DetailQuestion.yesNo('ownsPumpset', 'Do you own an irrigation pump set?'),
    DetailQuestion.yesNo('ownsTractor', 'Do you own a tractor?'),
    DetailQuestion.yesNo('hasSchoolChildren', 'Do you have school-going children?'),
  ]),
  DetailGroup('PM-KISAN exclusions', Icons.rule_folder_outlined, [
    DetailQuestion.yesNo('isIncomeTaxPayer', 'Did anyone in your family pay income tax last year?'),
    DetailQuestion.yesNo('isGovtEmployee', 'Is anyone in your family a serving or retired government employee?', hint: 'Multi-tasking / Class IV staff do not count'),
    DetailQuestion.yesNo('hasPensionOf10kOrMore', 'Does anyone in your family get a pension of ₹10,000 a month or more?'),
    DetailQuestion.yesNo('holdsConstitutionalPost', 'Is anyone a current or former MP, MLA, minister or mayor?'),
    DetailQuestion.yesNo('isRegisteredProfessional', 'Is anyone a registered doctor, engineer, lawyer, CA or architect in practice?'),
    DetailQuestion.yesNo('isNri', 'Is your family a Non-Resident Indian family?'),
    DetailQuestion.yesNo('isInstitutionalLandholder', 'Is the land held by an institution rather than a family?'),
  ]),
];

/// Every question, in one list, in the order asked.
List<DetailQuestion> get allDetailQuestions => [for (final g in detailGroups) ...g.questions];

DetailQuestion? detailQuestion(String key) {
  for (final q in allDetailQuestions) {
    if (q.key == key) return q;
  }
  return null;
}

class FarmDetailsScreen extends ConsumerWidget {
  const FarmDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(farmDetailsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Farm & scheme details')),
      body: ResponsiveScope(
        child: details.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(farmDetailsProvider)),
          data: (d) => _Form(initial: d),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.initial});

  final FarmDetails initial;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final Map<String, dynamic> _answers = Map<String, dynamic>.from(widget.initial.answers);
  final _land = TextEditingController();
  DateTime? _dob;
  bool _saving = false;
  bool _landLoaded = false;

  @override
  void initState() {
    super.initState();
    _dob = DateTime.tryParse((widget.initial.text('dateOfBirth')) ?? '');
  }

  @override
  void dispose() {
    _land.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 40),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final changes = <String, Object?>{for (final q in allDetailQuestions) q.key: _answers[q.key]};
      changes['dateOfBirth'] = _dob == null ? null : _iso(_dob!);
      await ref.read(profileRepositoryProvider).saveDetails(changes);
      final land = double.tryParse(_land.text.trim());
      if (land != null) await ref.read(profileRepositoryProvider).saveLandHolding(land);
      ref.invalidate(farmDetailsProvider);
      ref.invalidate(farmerProfileProvider);
      // New answers change how every scheme is judged.
      ref.invalidate(eligibilitySummaryProvider);
      ref.invalidate(schemeEligibilityProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved. Schemes will use these answers.')));
      setState(() => _saving = false);
      Navigator.of(context).maybePop();
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    // Prefill the land size once the profile is known.
    final profile = ref.watch(farmerProfileProvider).value;
    if (!_landLoaded && profile != null) {
      _landLoaded = true;
      if (profile.landHoldingHectares > 0) _land.text = profile.landHoldingHectares.toString();
    }
    final answered = allDetailQuestions.where((q) => _answers[q.key] != null).length + (_dob != null ? 1 : 0);
    final total = allDetailQuestions.length + 1;

    return ListView(
      padding: context.pagePadding,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Answer once. Use everywhere.', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text('These answers stay on your profile and are used to check every government scheme, so you never have to type them again. Skip anything you are not sure about.', style: text.bodySmall),
            AppSpacing.gapSm,
            LinearProgressIndicator(value: answered / total, minHeight: 6, borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: AppSpacing.xs),
            Text('$answered of $total answered', key: const Key('answered-count'), style: text.labelSmall),
          ]),
        ),
        AppSpacing.gapMd,
        _GroupCard(
          title: 'Land and age',
          icon: Icons.landscape_outlined,
          children: [
            TextField(
              key: const Key('land-hectares'),
              controller: _land,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total land you farm (hectares)', helperText: '1 acre = 0.4 hectare'),
            ),
            AppSpacing.gapSm,
            ListTile(
              key: const Key('dob-tile'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of birth'),
              subtitle: Text(_dob == null ? 'Not set' : '${_iso(_dob!)}  (age ${_age(_dob!)})'),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDob,
            ),
          ],
        ),
        for (final g in detailGroups) ...[
          AppSpacing.gapMd,
          _GroupCard(title: g.title, icon: g.icon, children: [for (final q in g.questions) _Question(q: q, answers: _answers, onChanged: () => setState(() {}))]),
        ],
        AppSpacing.gapLg,
        AppButton(label: 'Save details', expand: true, isLoading: _saving, onPressed: _save),
        AppSpacing.gapLg,
      ],
    );
  }

  int _age(DateTime dob) {
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) years -= 1;
    return years;
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Material(
        type: MaterialType.transparency,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: colors.primary), const SizedBox(width: AppSpacing.sm), Text(title, style: Theme.of(context).textTheme.titleSmall)]),
        AppSpacing.gapSm,
        ...children,
      ]),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.q, required this.answers, required this.onChanged});

  final DetailQuestion q;
  final Map<String, dynamic> answers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final Widget control;
    if (q.options == null) {
      final value = answers[q.key] as bool?;
      control = Wrap(spacing: AppSpacing.sm, children: [
        ChoiceChip(key: Key('${q.key}-yes'), label: const Text('Yes'), selected: value == true, onSelected: (_) => _set(value == true ? null : true)),
        ChoiceChip(key: Key('${q.key}-no'), label: const Text('No'), selected: value == false, onSelected: (_) => _set(value == false ? null : false)),
      ]);
    } else if (q.multi) {
      final chosen = ((answers[q.key] as List?) ?? const []).cast<String>();
      control = Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
        for (final e in q.options!.entries)
          FilterChip(
            key: Key('${q.key}-${e.key}'),
            label: Text(e.value),
            selected: chosen.contains(e.key),
            onSelected: (on) {
              // Read at tap time, so two quick taps both count.
              final now = ((answers[q.key] as List?) ?? const []).cast<String>();
              _set([...now.where((c) => c != e.key), if (on) e.key]..sort());
            },
          ),
      ]);
    } else {
      final value = answers[q.key] as String?;
      control = Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
        for (final e in q.options!.entries) ChoiceChip(key: Key('${q.key}-${e.key}'), label: Text(e.value), selected: value == e.key, onSelected: (_) => _set(value == e.key ? null : e.key)),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q.title, style: text.bodyMedium),
        if (q.hint != null) Text(q.hint!, style: text.bodySmall?.copyWith(color: colors.textMuted)),
        const SizedBox(height: AppSpacing.xs),
        control,
      ]),
    );
  }

  void _set(Object? value) {
    if (value == null || (value is List && value.isEmpty)) {
      answers.remove(q.key);
    } else {
      answers[q.key] = value;
    }
    onChanged();
  }
}
