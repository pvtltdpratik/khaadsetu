import 'package:flutter/material.dart';

import '../../../../core/animation/pop_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';

/// Where a delivery is: who is bringing it, how far away they are, and the code
/// to read out on arrival. It works for a buyer following an order and for a
/// sender following a load ([DeliveryTracking.isP2p]); what the person can do
/// is passed in as callbacks, and a button shows only when its callback is given
/// and the delivery is in a state where it applies.
class DeliveryTrackingCard extends StatelessWidget {
  const DeliveryTrackingCard({
    super.key,
    required this.delivery,
    this.goodsAmount = 0,
    this.onSwitchToPickup,
    this.onCancel,
    this.onRate,
    this.onHandOver,
  });

  final DeliveryTracking delivery;

  /// What the goods cost, to explain the cash to hand over (an order only).
  final double goodsAmount;
  final VoidCallback? onSwitchToPickup;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;

  /// A sender confirms the partner has collected the load (asks for his code).
  final VoidCallback? onHandOver;

  static const _orderSteps = ['Finding a partner', 'At the center', 'On the way', 'Delivered'];
  static const _loadSteps = ['Finding a partner', 'Pickup', 'On the way', 'Delivered'];

  int get _step => switch (delivery.status) {
        DeliveryStatus.open => 0,
        DeliveryStatus.assigned => 1,
        DeliveryStatus.inTransit => 2,
        DeliveryStatus.delivered => 3,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final d = delivery;
    final partner = d.partner;
    final ended = d.status == DeliveryStatus.cancelled || d.status == DeliveryStatus.fallback;
    final mapTarget = d.partnerLocation ?? (d.status == DeliveryStatus.assigned ? d.pickup : d.drop);

    return Container(
      key: const Key('delivery-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(d.status), color: ended ? colors.textMuted : colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(d.stage, key: ValueKey(d.stage), style: text.titleSmall),
                ),
              ),
            ],
          ),
          if (!ended) ...[
            AppSpacing.gapSm,
            _Steps(labels: d.isP2p ? _loadSteps : _orderSteps, current: _step),
          ],
          if (d.isP2p && d.description.isNotEmpty) ...[
            AppSpacing.gapSm,
            Text('${d.description} · ${d.weightKg.toStringAsFixed(d.weightKg == d.weightKg.roundToDouble() ? 0 : 1)} kg', style: text.bodyMedium),
          ],
          if (partner != null) ...[
            AppSpacing.gapSm,
            _PartnerRow(partner: partner),
          ],
          if (d.etaMinutes != null && d.status != DeliveryStatus.delivered) ...[
            AppSpacing.gapSm,
            Row(children: [
              Icon(Icons.timer_outlined, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'About ${d.etaMinutes} min · ${d.distanceToNextStopKm?.toStringAsFixed(1)} km from ${_nextStopWords(d)}',
                  key: const Key('delivery-eta'),
                  style: text.bodyMedium,
                ),
              ),
            ]),
          ],
          if (d.dropCode != null && d.status.isLive) ...[
            AppSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(d.isP2p ? 'Delivery code: tell it to the receiver' : 'Your delivery code', style: text.labelMedium?.copyWith(color: colors.primary)),
                  PopIn(
                    delay: const Duration(milliseconds: 250),
                    child: Text(d.dropCode!, key: const Key('drop-code'), style: text.displaySmall?.copyWith(letterSpacing: 8, color: colors.primary, fontWeight: FontWeight.w800)),
                  ),
                  Text(
                    d.isP2p ? 'The receiver reads it to the delivery partner when the load arrives.' : 'Read it to the delivery partner when the order reaches you. Not before.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: colors.primary),
                  ),
                ],
              ),
            ),
          ],
          if (!ended && d.status != DeliveryStatus.delivered) ...[
            AppSpacing.gapSm,
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.payments_outlined, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(_paymentWords(d), key: const Key('delivery-payment'), style: text.bodySmall)),
            ]),
          ],
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (partner != null && partner.phone.isNotEmpty && d.status.isLive)
                OutlinedButton.icon(onPressed: () => callPhone(context, partner.phone), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call partner')),
              if (d.status.isLive && d.status != DeliveryStatus.open)
                OutlinedButton.icon(
                  onPressed: () => openInMaps(context, latitude: mapTarget.latitude, longitude: mapTarget.longitude),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(d.partnerLocation != null ? 'See on map' : 'Open map'),
                ),
              if (d.isP2p && d.status == DeliveryStatus.assigned && onHandOver != null)
                FilledButton.icon(onPressed: onHandOver, icon: const Icon(Icons.inventory_2_outlined, size: 18), label: const Text('Hand over the load')),
              if (d.canSwitchToPickup && onSwitchToPickup != null)
                TextButton.icon(onPressed: onSwitchToPickup, icon: const Icon(Icons.storefront_rounded, size: 18), label: const Text('I will collect it instead')),
              if (d.canCancel && onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.close_rounded, size: 18, color: colors.danger),
                  label: Text('Cancel', style: TextStyle(color: colors.danger)),
                ),
              if (d.status == DeliveryStatus.delivered && !d.rated && onRate != null)
                FilledButton.icon(onPressed: onRate, icon: const Icon(Icons.star_rounded, size: 18), label: const Text('Rate the delivery')),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _icon(DeliveryStatus s) => switch (s) {
        DeliveryStatus.open => Icons.search_rounded,
        DeliveryStatus.assigned => Icons.directions_car_outlined,
        DeliveryStatus.inTransit => Icons.local_shipping_rounded,
        DeliveryStatus.delivered => Icons.check_circle_rounded,
        DeliveryStatus.cancelled => Icons.block_rounded,
        DeliveryStatus.fallback => Icons.storefront_rounded,
      };

  static String _nextStopWords(DeliveryTracking d) => switch (d.nextStop) {
        'center' => 'the center',
        'pickup' => 'the pickup',
        'receiver' => 'the receiver',
        _ => 'you',
      };

  String _paymentWords(DeliveryTracking d) {
    if (d.isP2p) {
      return d.feePayer == 'receiver'
          ? 'The receiver pays the delivery fee, ${formatRupees(d.fee)}, in cash on arrival.'
          : 'You pay the delivery fee, ${formatRupees(d.fee)}, in cash to the partner when they collect the load.';
    }
    return 'Pay ${formatRupees(d.payableAmount)} in cash on arrival'
        '${goodsAmount > 0 ? ' (goods ${formatRupees(goodsAmount)} + delivery ${formatRupees(d.fee)})' : ''}.';
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final small = Theme.of(context).textTheme.labelSmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: i == 0 ? const SizedBox() : _bar(i <= current ? colors.primary : colors.border)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= current ? colors.primary : colors.surface,
                      border: Border.all(color: i <= current ? colors.primary : colors.border, width: 2),
                    ),
                  ),
                  Expanded(child: i == labels.length - 1 ? const SizedBox() : _bar(i < current ? colors.primary : colors.border)),
                ]),
                const SizedBox(height: 4),
                Text(labels[i], textAlign: TextAlign.center, style: small?.copyWith(color: i <= current ? colors.textPrimary : colors.textMuted, fontWeight: i == current ? FontWeight.w700 : null)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _bar(Color color) => AnimatedContainer(duration: const Duration(milliseconds: 260), height: 3, color: color);
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.partner});

  final PartnerInfo partner;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: colors.primaryContainer, child: Icon(Icons.person_rounded, color: colors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(partner.name, style: text.titleSmall),
              Text(
                '${partner.vehicleLabel} · ${partner.vehicleNumber}'
                '${partner.ratingCount > 0 ? ' · ★ ${partner.ratingAvg.toStringAsFixed(1)} (${partner.ratingCount})' : ' · new'}',
                style: text.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
