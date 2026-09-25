import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../farmer/profile/presentation/providers/profile_providers.dart';

/// The PGS-India steps, in order. Ticking one is remembered on the phone.
const pgsSteps = [
  ('group', 'Form a local group of 5 to 50 farmers', 'Ideally neighbours within 5 to 10 km. Choose one member as the group leader.'),
  ('register', 'Register the group on the PGS-India portal', "The leader registers at pgs.dacnet.nic.in with each member's name, survey number and crops. Each member gets a PGS ID once approved."),
  ('pledge', 'Sign the organic pledge', 'Every member promises to use no synthetic fertilizer, pesticide or weedkiller on the registered land.'),
  ('diary', 'Keep a farm diary', 'Write down seed, manure, sprays, sowing and harvest dates. Keep bills for bio-inputs you buy.'),
  ('appraisal', 'Take part in peer appraisal', 'At least two group members visit each farm and check for signs of chemical use and that the crops match the list.'),
  ('green', 'Receive PGS-Green while converting', 'Your produce is sold as "under conversion to organic", not yet as organic.'),
  ('organic', 'Receive PGS-Organic', 'After the conversion period (about 2 years for seasonal crops, 3 for perennials) the Regional Council issues the organic certificate.'),
];

const pgsDos = ['Compost, vermicompost, green manure, neem cake and other natural inputs', 'Seeds that are untreated, or treated only with natural methods', 'Crop rotation and mixed cropping', 'A buffer strip or drain where a neighbour uses chemicals'];
const pgsDonts = ['Urea, DAP, MOP or any synthetic fertilizer', 'Chemical pesticides, weedkillers and growth regulators', 'GM seeds', 'Burning crop residue'];

final pgsProgressProvider = NotifierProvider<PgsProgress, Set<String>>(PgsProgress.new);

class PgsProgress extends Notifier<Set<String>> {
  static const _key = 'pgs_steps_done';

  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = (prefs.getStringList(_key) ?? const []).toSet();
    } catch (_) {}
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
    try {
      await (await SharedPreferences.getInstance()).setStringList(_key, next.toList());
    } catch (_) {}
  }
}

class OrganicCertificationScreen extends ConsumerWidget {
  const OrganicCertificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final details = ref.watch(farmDetailsProvider).value;
    final done = ref.watch(pgsProgressProvider);
    final organic = details?.flag('practisesOrganic');
    final group = details?.flag('inFarmerGroup');
    final ready = organic == true && group == true;
    final headline = ready
        ? 'You are ready to apply'
        : organic == false
            ? 'Start with a small plot'
            : 'Check what you need';
    final body = ready
        ? 'You farm organically and you are in a group. Your group can register for PGS-India now.'
        : organic == false
            ? 'You can switch a field at a time. The conversion period starts the day you join PGS-India.'
            : group == false
                ? 'You need a group of at least 5 farmers. Ask neighbours who also farm organically or want to.'
                : 'Tell us about your farming and group in your farm details, and we will show where you stand.';
    return Scaffold(
      appBar: AppBar(title: const Text('Organic certification')),
      body: ResponsiveScope(
        child: ListView(
          padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
          children: [
            Container(
              key: const Key('pgs-readiness'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: ready ? colors.success.withValues(alpha: 0.12) : colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(ready ? Icons.verified_outlined : Icons.eco_outlined, color: ready ? colors.success : colors.primary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(headline, style: text.titleMedium))]),
                const SizedBox(height: AppSpacing.xs),
                Text(body, key: const Key('pgs-readiness-body')),
              ]),
            ),
            AppSpacing.gapMd,
            Text('PGS-India: the free route', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('A government scheme where farmers certify each other. There is no fee for inspection, application or renewal, and it usually takes 4 to 8 weeks from forming a group to the first certificate. It is for selling in India. To export, you need the paid NPOP certificate.', style: text.bodyMedium?.copyWith(color: colors.textMuted)),
            AppSpacing.gapMd,
            Text('Your steps (${done.length} of ${pgsSteps.length} done)', key: const Key('pgs-count'), style: text.titleMedium),
            for (final s in pgsSteps)
              CheckboxListTile(
                key: Key('step-${s.$1}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: done.contains(s.$1),
                onChanged: (_) => ref.read(pgsProgressProvider.notifier).toggle(s.$1),
                title: Text(s.$2),
                subtitle: Text(s.$3),
              ),
            AppSpacing.gapMd,
            Text('Keep to these rules', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (final d in pgsDos) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle_rounded, size: 18, color: colors.success), const SizedBox(width: 8), Expanded(child: Text(d))]),
            const SizedBox(height: AppSpacing.xs),
            for (final d in pgsDonts) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.cancel_rounded, size: 18, color: colors.danger), const SizedBox(width: 8), Expanded(child: Text(d))]),
            AppSpacing.gapMd,
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text('Money help: the Paramparagat Krishi Vikas Yojana (PKVY) supports groups that go organic. See it in Schemes and check your eligibility.', style: text.bodyMedium),
            ),
            AppSpacing.gapMd,
            FilledButton.icon(
              key: const Key('open-portal'),
              onPressed: () => launchUrl(Uri.parse('https://pgs.dacnet.nic.in'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open the PGS-India portal'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Ask your village center or Krishi Vigyan Kendra to help with registration. Rules can change, so confirm on the portal.', style: text.labelSmall?.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
