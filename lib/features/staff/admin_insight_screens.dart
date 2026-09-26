import 'package:flutter/material.dart';
import '../../core/l10n/app_locale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import 'approvals_screen.dart' show StaffScope;
import 'farmer_card_screen.dart';

final communityAiOverviewProvider = FutureProvider.autoDispose<Json>((ref) async => asJson(await ref.watch(apiClientProvider).get('/v1/admin/community/ai')));
final schemeCoverageProvider = FutureProvider.autoDispose<Json>((ref) async => asJson(await ref.watch(apiClientProvider).get('/v1/admin/scheme-coverage')));
final centerActivityProvider = FutureProvider.autoDispose.family<Json, String>((ref, id) async => asJson(await ref.watch(apiClientProvider).get('/v1/admin/centers/${Uri.encodeComponent(id)}/activity')));

/// How the AI answers in the community are doing: how many were found helpful, and the posts it would not answer.
class CommunityAiScreen extends ConsumerWidget {
  const CommunityAiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(communityAiOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Tx('Community AI')),
      body: ResponsiveScope(
        child: data.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(communityAiOverviewProvider)),
          data: (d) {
            final q = d.obj('quality');
            final states = d.obj('states');
            final flagged = d.list('flagged');
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: 'Were the answers helpful?',
                icon: Icons.thumbs_up_down_outlined,
                child: Column(children: [
                  KitRow('Found helpful', '${q.int_('helpful')}'),
                  KitRow('Not helpful', '${q.int_('notHelpful')}'),
                  KitRow('Share helpful', q['share'] == null ? 'No votes yet' : '${q.int_('share')}%', bold: true),
                ]),
              ),
              KitCard(
                index: 1,
                title: 'Posts by state',
                icon: Icons.forum_outlined,
                child: Column(children: [for (final e in states.entries) KitRow(_stateLabel(e.key), '${e.value}')]),
              ),
              KitCard(
                index: 2,
                title: 'Not answered: off topic or abusive (${flagged.length})',
                icon: Icons.flag_outlined,
                child: flagged.isEmpty
                    ? Text('Nothing flagged.', key: const Key('flagged-empty'), style: text.bodyMedium)
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final f in flagged)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(f.str('title'), style: text.titleSmall)), StatusPill(f.str('reason'), tone: f.str('reason') == 'abusive' ? Tone.bad : Tone.warn)]),
                              Text('${f.str('farmerName')}: ${f.str('content')}', maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                            ]),
                          ),
                      ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  String _stateLabel(String s) => switch (s) { 'done' => 'Answered by AI', 'pending' => 'Waiting for the AI', 'skipped' => 'Not answered (limit or error)', 'flagged' => 'Flagged', _ => 'Answered by the standard draft' };
}

/// Every farmer with saved answers: how many schemes he meets outright, so the admin knows who to help and which schemes
/// reach the most people.
class SchemeCoverageScreen extends ConsumerWidget {
  const SchemeCoverageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(schemeCoverageProvider);
    return Scaffold(
      appBar: AppBar(title: const Tx('Scheme reach')),
      body: ResponsiveScope(
        child: data.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(schemeCoverageProvider)),
          data: (d) {
            final schemes = d.list('schemes')..sort((a, b) => b.int_('eligible').compareTo(a.int_('eligible')));
            final farmers = d.list('farmers');
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: 'Schemes: farmers who are eligible',
                icon: Icons.account_balance_outlined,
                child: Column(children: [for (final s in schemes.take(15)) KitRow(s.str('name'), '${s.int_('eligible')} eligible · ${s.int_('possible')} maybe')]),
              ),
              KitCard(
                index: 1,
                title: 'Farmers (${farmers.length})',
                icon: Icons.groups_outlined,
                child: Column(children: [
                  for (final f in farmers.take(60))
                    ListTile(
                      key: Key('cover-${f.str('farmerId')}'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(f.str('name')),
                      subtitle: Text(f.str('village')),
                      trailing: Text('${f.int_('eligible')} eligible', style: text.titleSmall),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FarmerCardScreen(scope: StaffScope.admin, farmerId: f.str('farmerId')))),
                    ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

/// A center as the admin judges it: sales against the target, what it owes and is owed, papers waiting for it, and its diary.
class CenterActivityScreen extends ConsumerWidget {
  const CenterActivityScreen({super.key, required this.centerId});

  final String centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(centerActivityProvider(centerId));
    return Scaffold(
      appBar: AppBar(title: const Tx('Center activity')),
      body: ResponsiveScope(
        child: data.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(centerActivityProvider(centerId))),
          data: (d) {
            final c = d.obj('center');
            final sales = d.obj('sales');
            final target = sales.obj('target');
            final waiting = d.obj('waitingForCheck');
            final profile = d.obj('profile');
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: c.str('name'),
                icon: Icons.storefront_outlined,
                trailing: StatusPill(c.str('status'), tone: c.str('status') == 'active' ? Tone.good : Tone.bad),
                child: Column(children: [
                  KitRow('Operator', c.str('operatorName', '-')),
                  KitRow('Last seen', c.str('lastActiveAt').length >= 10 ? c.str('lastActiveAt').substring(0, 16).replaceFirst('T', ' ') : '-'),
                  if (profile.isNotEmpty) KitRow('KYC', profile.str('kycStatus')),
                ]),
              ),
              KitCard(
                index: 1,
                title: 'Sales',
                icon: Icons.trending_up,
                child: Column(children: [
                  KitRow('This month', '₹${sales.obj('month').num_('sales').toStringAsFixed(0)}'),
                  KitRow('Last month', '₹${sales.obj('lastMonth').num_('sales').toStringAsFixed(0)}'),
                  if (target.num_('monthlySales') > 0) KitRow('Target', '${target.int_('percent')}% of ₹${target.num_('monthlySales').toStringAsFixed(0)}'),
                  if (sales.obj('leaderboard')['rank'] != null) KitRow('Rank', '#${sales.obj('leaderboard').int_('rank')} of ${sales.obj('leaderboard').int_('of')}'),
                  KitRow('Credit given, not paid', '₹${d.num_('creditOutstanding').toStringAsFixed(0)}'),
                ]),
              ),
              KitCard(
                index: 2,
                title: 'Waiting for this center',
                icon: Icons.pending_actions_outlined,
                child: Column(children: [KitRow('Vehicles to check', '${waiting.int_('vehicles')}'), KitRow('Products to check', '${waiting.int_('listings')}')]),
              ),
              KitCard(
                index: 3,
                title: 'What the operator did for farmers',
                icon: Icons.edit_note_outlined,
                child: d.obj('diary').isEmpty ? const Text('Nothing written yet.') : Column(children: [for (final e in d.obj('diary').entries) KitRow(e.key, '${e.value}')]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
