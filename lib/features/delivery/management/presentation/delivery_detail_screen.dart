import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/kit.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../../staff/approvals_screen.dart' show StaffScope;
import '../../../staff/farmer_card_screen.dart';
import '../../domain/entities/delivery_models.dart';
import '../domain/management_models.dart';
import 'management_providers.dart';
import 'partner_review_screen.dart';

StaffScope _staffScope(ManagementScope s) => s == ManagementScope.admin ? StaffScope.admin : StaffScope.operator;

Tone _statusTone(DeliveryStatus s) => switch (s) {
      DeliveryStatus.delivered => Tone.good,
      DeliveryStatus.cancelled => Tone.bad,
      DeliveryStatus.open => Tone.warn,
      _ => Tone.info,
    };

String _statusText(DeliveryStatus s) => switch (s) {
      DeliveryStatus.open => 'Finding a driver',
      DeliveryStatus.assigned => 'Driver collecting',
      DeliveryStatus.inTransit => 'On the road',
      DeliveryStatus.delivered => 'Delivered',
      DeliveryStatus.cancelled => 'Cancelled',
      DeliveryStatus.fallback => 'Collect at center',
    };

/// One delivery in full: the route, and who to contact — the buyer (phone, email) and the driver (phone, vehicle) —
/// each with a way to open their whole profile.
class DeliveryDetailScreen extends ConsumerWidget {
  const DeliveryDetailScreen({super.key, required this.scope, required this.id});

  final ManagementScope scope;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = DeliveryKey(scope, id);
    final detail = ref.watch(managedDeliveryDetailProvider(key));
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Delivery')),
        body: SafeArea(
          child: detail.when(
            skipLoadingOnReload: true,
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(managedDeliveryDetailProvider(key))),
            data: (d) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [ContentContainer(maxWidth: 720, child: _Body(scope: scope, d: d))],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.scope, required this.d});

  final ManagementScope scope;
  final ManagedDelivery d;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kg = d.weightKg == d.weightKg.roundToDouble() ? d.weightKg.toStringAsFixed(0) : d.weightKg.toStringAsFixed(1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(d.isP2p ? 'Farmer to farmer' : 'Order delivery', style: text.headlineSmall)),
        StatusPill(_statusText(d.status), tone: _statusTone(d.status)),
      ]),
      AppSpacing.gapSm,
      KitCard(
        title: 'Load',
        icon: Icons.inventory_2_outlined,
        child: Column(children: [
          KitRow('Weight', '$kg kg'),
          KitRow('Distance', '${d.distanceKm.toStringAsFixed(1)} km'),
          KitRow('Delivery fee', formatRupees(d.fee)),
          if (d.goodsAmount > 0) KitRow('Goods value', formatRupees(d.goodsAmount)),
          if (d.cashToCollect > 0) KitRow('Cash to collect', formatRupees(d.cashToCollect), bold: true),
        ]),
      ),
      KitCard(
        index: 1,
        title: 'Pickup',
        icon: Icons.trip_origin,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (d.centerName != null) KitRow('Center', d.centerName!),
          if ((d.centerVillage ?? '').isNotEmpty || (d.centerDistrict ?? '').isNotEmpty) KitRow('Place', [d.centerVillage, d.centerDistrict].whereType<String>().where((s) => s.isNotEmpty).join(', ')),
          if ((d.pickupLabel ?? '').isNotEmpty) KitRow('Address', d.pickupLabel!),
          if ((d.centerPhone ?? '').isNotEmpty) ...[
            AppSpacing.gapSm,
            OutlinedButton.icon(key: const Key('call-center'), onPressed: () => callPhone(context, d.centerPhone!), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call the center')),
          ],
        ]),
      ),
      KitCard(
        index: 2,
        title: 'Drop',
        icon: Icons.place_outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KitRow('Village', d.dropVillage.isEmpty ? '-' : d.dropVillage),
          if ((d.dropLabel ?? '').isNotEmpty) KitRow('Address', d.dropLabel!),
          if ((d.dropNote ?? '').isNotEmpty) KitRow('Note', d.dropNote!),
        ]),
      ),
      KitCard(
        index: 3,
        title: 'Buyer',
        icon: Icons.person_outline,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.buyerName, style: text.titleSmall),
          AppSpacing.gapSm,
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
            if ((d.buyerPhone ?? '').isNotEmpty) OutlinedButton.icon(key: const Key('call-buyer'), onPressed: () => callPhone(context, d.buyerPhone!), icon: const Icon(Icons.call_rounded, size: 18), label: Text(d.buyerPhone!)),
            if ((d.buyerEmail ?? '').isNotEmpty) OutlinedButton.icon(key: const Key('email-buyer'), onPressed: () => emailPerson(context, d.buyerEmail!), icon: const Icon(Icons.mail_outline_rounded, size: 18), label: Text(d.buyerEmail!)),
          ]),
          if (d.requesterId != null) ...[
            AppSpacing.gapSm,
            TextButton.icon(
              key: const Key('buyer-full-profile'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FarmerCardScreen(scope: _staffScope(scope), farmerId: d.requesterId!))),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Full profile'),
            ),
          ],
        ]),
      ),
      if (d.hasPartner)
        KitCard(
          index: 4,
          title: 'Delivery partner',
          icon: Icons.local_shipping_outlined,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.partnerName ?? 'Partner', style: text.titleSmall),
            Text('${d.vehicleType?.label ?? ''} ${d.vehicleNumber ?? ''}${d.ratingAvg == null || d.ratingAvg == 0 ? '' : ' · ★ ${d.ratingAvg!.toStringAsFixed(1)}'}', style: text.bodyMedium),
            AppSpacing.gapSm,
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              if ((d.partnerPhone ?? '').isNotEmpty) OutlinedButton.icon(key: const Key('call-partner'), onPressed: () => callPhone(context, d.partnerPhone!), icon: const Icon(Icons.call_rounded, size: 18), label: Text(d.partnerPhone!)),
            ]),
            AppSpacing.gapSm,
            TextButton.icon(
              key: const Key('partner-full-profile'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PartnerReviewScreen(scope: scope, userId: d.partnerId!))),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Full profile'),
            ),
          ]),
        ),
    ]);
  }
}
