import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/animation/pressable.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/presentation/providers/centers_providers.dart';
import '../../domain/entities/delivery_models.dart';
import '../providers/delivery_providers.dart';
import '../widgets/live_refresh.dart';
import '../widgets/partner_application_form.dart';
import '../widgets/partner_job_cards.dart';
import '../widgets/rating_sheet.dart';

/// "Deliver for others": the same farmer, with one more thing they can do. What
/// it shows follows where their application is: the form, a waiting note, or the
/// working screen (free-now switch, the job in hand, offers, money, trips).
class DeliveryHubScreen extends ConsumerWidget {
  const DeliveryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(partnerProfileProvider);
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Deliver for others')),
        body: SafeArea(
          child: profile.when(
            skipLoadingOnReload: true,
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(partnerProfileProvider)),
            data: (p) => ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: switch (p.status) {
                    PartnerStatus.none || PartnerStatus.draft || PartnerStatus.rejected => PartnerApplicationForm(profile: p),
                    PartnerStatus.pending => _Waiting(profile: p),
                    PartnerStatus.suspended => const _Suspended(),
                    PartnerStatus.approved => _Dashboard(profile: p),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Waiting extends ConsumerWidget {
  const _Waiting({required this.profile});

  final PartnerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return LiveRefresh(
      interval: const Duration(seconds: 45),
      onTick: () => ref.invalidate(partnerProfileProvider),
      child: Container(
        key: const Key('waiting-card'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
        child: Column(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 40, color: colors.warning),
            AppSpacing.gapSm,
            Text('Waiting for the village center', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${profile.reviewCenterName ?? 'The village center'} is checking your licence and RC. You will be told as soon as they decide. You can still order and use the app as usual.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            AppSpacing.gapMd,
            Text('${profile.vehicleType?.label ?? 'Vehicle'} · ${profile.vehicleNumber} · up to ${profile.capacityKg ?? '?'} kg', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Suspended extends StatelessWidget {
  const _Suspended();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const Key('suspended-card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.danger.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.danger)),
      child: Text('Your delivery account is paused. Please contact your village center.', style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _Dashboard extends ConsumerStatefulWidget {
  const _Dashboard({required this.profile});

  final PartnerProfile profile;

  @override
  ConsumerState<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<_Dashboard> {
  bool _busy = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_shareLocation());
  }

  /// Tells the server where I am, so the nearest partner gets the offer and the
  /// buyer can follow the delivery. Best effort: no GPS is not an error.
  Future<void> _shareLocation({bool force = false}) async {
    if (!force && !widget.profile.online) return;
    try {
      final here = await ref.read(deviceLocationProvider).current();
      await ref.read(deliveryRepositoryProvider).shareLocation(latitude: here.latitude, longitude: here.longitude);
    } catch (_) {
      // GPS off or slow: offers still come, from where the server last knew me.
    }
  }

  void _refresh() {
    ref
      ..invalidate(partnerOffersProvider)
      ..invalidate(partnerActiveProvider);
    unawaited(_shareLocation());
  }

  void _say(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() work) async {
    setState(() => _busy = true);
    try {
      await work();
    } catch (err) {
      _say('$err');
      ref
        ..invalidate(partnerOffersProvider)
        ..invalidate(partnerActiveProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setOnline(bool on) => _run(() async {
        await ref.read(deliveryRepositoryProvider).setOnline(on);
        ref.invalidate(partnerProfileProvider);
        if (on) unawaited(_shareLocation(force: true));
      });

  Future<void> _accept(PartnerJob job) => _run(() async {
        await ref.read(deliveryRepositoryProvider).accept(job.id);
        _refresh();
        _say('It is yours. Go and collect it.');
      });

  Future<void> _decline(PartnerJob job) => _run(() async {
        await ref.read(deliveryRepositoryProvider).decline(job.id);
        _refresh();
      });

  Future<void> _giveBack(PartnerJob job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give this job back?'),
        content: const Text('It goes to other partners. Handing back too many jobs counts against your record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Give it back')),
        ],
      ),
    );
    if (ok == true) await _decline(job);
  }

  Future<void> _enterCode(PartnerJob job) async {
    final code = await showDeliveryCodeDialog(context, help: job.isP2p ? 'Ask the receiver for the 4-digit delivery code.' : 'Ask the farmer for the 4-digit delivery code in their app.');
    if (code == null || !mounted) return;
    var done = false;
    await _run(() async {
      await ref.read(deliveryRepositoryProvider).deliver(jobId: job.id, otp: code);
      done = true;
      _refresh();
      ref.invalidate(walletProvider);
      _say('Delivered. ${formatRupees(job.fee)} is yours.');
    });
    if (done && mounted) {
      final rating = await showRatingDialog(context, title: 'How was the farmer?', hint: 'Anything to add? (optional)');
      if (rating != null) {
        try {
          await ref.read(deliveryRepositoryProvider).rateBuyer(jobId: job.id, stars: rating.stars, comment: rating.comment);
        } catch (err) {
          _say('$err');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final offers = ref.watch(partnerOffersProvider);
    final active = ref.watch(partnerActiveProvider);
    final activeJobs = active.value ?? const <PartnerJob>[];

    if (_editing) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextButton.icon(onPressed: () => setState(() => _editing = false), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Back')),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Text('Changing your vehicle, its number, how much it carries or your phone sends you back to the village center to be checked again. Days, hours and distance change freely.', style: text.bodySmall),
        ),
        PartnerApplicationForm(profile: p, submit: false),
      ]);
    }

    return LiveRefresh(
      interval: const Duration(seconds: 15),
      onTick: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(child: _FreeNowCard(profile: p, busy: _busy, onChanged: _setOnline, onEdit: () => setState(() => _editing = true))),
          if (activeJobs.length > 1) ...[
            AppSpacing.gapSm,
            Container(
              key: const Key('batch-banner'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: colors.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.inventory_2_outlined, color: colors.info),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('You are carrying ${activeJobs.length} orders on this trip. Collect them one by one, then deliver each with its own code.', style: text.bodyMedium)),
              ]),
            ),
          ],
          for (final (i, job) in activeJobs.indexed) ...[
            AppSpacing.gapMd,
            FadeSlideIn(index: i, child: ActiveJobCard(job: job, busy: _busy, onEnterCode: () => _enterCode(job), onGiveBack: () => _giveBack(job))),
          ],
          AppSpacing.gapLg,
          Text('Jobs for you', style: text.titleMedium),
          AppSpacing.gapSm,
          offers.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Center(child: CircularProgressIndicator())),
            error: (err, _) => Text('$err', style: text.bodyMedium?.copyWith(color: colors.danger)),
            data: (list) => list.isEmpty
                ? Container(
                    key: const Key('no-offers'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      p.online ? 'No jobs right now. Keep this screen open, we will tell you the moment one comes.' : 'Switch on "I can deliver now" to get jobs near you.',
                      style: text.bodyMedium,
                    ),
                  )
                : Column(children: [
                    for (final (i, job) in list.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: FadeSlideIn(index: i, child: OfferCard(job: job, busy: _busy, onAccept: () => _accept(job), onDecline: () => _decline(job))),
                      ),
                  ]),
          ),
          AppSpacing.gapLg,
          Text('My deliveries', style: text.titleMedium),
          AppSpacing.gapSm,
          _LinkTile(key: const Key('open-wallet'), icon: Icons.account_balance_wallet_outlined, title: 'My money', subtitle: 'What I earned and what I owe the center', onTap: () => context.push(RoutePaths.farmerDeliverWallet)),
          _LinkTile(key: const Key('open-trips'), icon: Icons.route_outlined, title: 'My trips', subtitle: 'Going somewhere with room to spare? Let farmers book it', onTap: () => context.push(RoutePaths.farmerDeliverTrips)),
          _LinkTile(key: const Key('open-loads'), icon: Icons.inventory_2_outlined, title: 'Send a load to a farmer', subtitle: 'Get something carried from your farm to another', onTap: () => context.push(RoutePaths.farmerLoads)),
        ],
      ),
    );
  }
}

class _FreeNowCard extends StatelessWidget {
  const _FreeNowCard({required this.profile, required this.busy, required this.onChanged, required this.onEdit});

  final PartnerProfile profile;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: profile.online ? colors.success : colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Its own Material, so the tile's ink is not painted under the card's colour.
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              key: const Key('online-switch'),
              contentPadding: EdgeInsets.zero,
              value: profile.online,
              onChanged: busy ? null : onChanged,
              title: Text('I can deliver now', style: text.titleMedium),
              subtitle: Text(profile.online ? 'You are on. Jobs near you will come to you.' : 'You are off. No jobs will be offered.'),
            ),
          ),
          Text(
            '${profile.vehicleType?.label ?? 'Vehicle'} · ${profile.vehicleNumber} · up to ${profile.capacityKg ?? '?'} kg · within ${profile.maxDistanceKm} km · ${profile.freeFrom} to ${profile.freeUntil}',
            style: text.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (profile.ratingCount > 0)
            Text('★ ${profile.ratingAvg.toStringAsFixed(1)} (${profile.ratingCount}) · ${profile.deliveriesDone} deliveries', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          Align(alignment: Alignment.centerRight, child: TextButton(key: const Key('edit-details'), onPressed: onEdit, child: const Text('Change my details'))),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
            child: Row(children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ]),
          ),
        ),
      ),
      ),
    );
  }
}
