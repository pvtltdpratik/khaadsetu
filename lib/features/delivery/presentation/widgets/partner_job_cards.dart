import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animation/pop_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';

String _kg(double kg) => kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

/// A job offered to the partner: the money first, then the load and the way.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.job, required this.onAccept, required this.onDecline, this.busy = false, this.now});

  final PartnerJob job;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool busy;

  /// The clock, so a test can pin how long is left.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final left = job.offerExpiresAt?.difference(now ?? DateTime.now());
    final minutes = left?.inMinutes.clamp(0, 24 * 60 * 30);
    return Container(
      key: Key('offer-${job.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(formatRupees(job.fee), style: text.headlineSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('${_kg(job.weightKg)} kg · ${job.distanceKm.toStringAsFixed(1)} km', style: text.titleSmall)),
              if (job.isP2p) _Tag(label: 'Farmer to farmer', color: colors.info),
              if (job.tripId != null) _Tag(label: 'Your trip', color: colors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (job.items.isNotEmpty) Text(job.items, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            Icon(Icons.trip_origin_rounded, size: 16, color: colors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(job.centerName ?? (job.pickup.label.isEmpty ? 'A farm' : job.pickup.label), style: text.bodySmall)),
          ]),
          Row(children: [
            Icon(Icons.place_rounded, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(job.dropVillage.isEmpty ? 'A farm nearby' : job.dropVillage, style: text.bodySmall)),
          ]),
          if (minutes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(minutes >= 120 ? 'Open until it is taken' : 'Answer within $minutes min', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          ],
          AppSpacing.gapSm,
          Row(children: [
            Expanded(child: OutlinedButton(key: Key('decline-${job.id}'), onPressed: busy ? null : onDecline, child: const Text('Not now'))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 2, child: FilledButton(key: Key('accept-${job.id}'), onPressed: busy ? null : onAccept, child: const Text('Accept'))),
          ]),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

/// The job he is doing: first go and collect (with the code that proves it is
/// him), then deliver (against the code the receiver reads out).
class ActiveJobCard extends StatelessWidget {
  const ActiveJobCard({super.key, required this.job, required this.onEnterCode, required this.onGiveBack, this.busy = false});

  final PartnerJob job;
  final VoidCallback onEnterCode;
  final VoidCallback onGiveBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final collecting = job.status == DeliveryStatus.assigned;
    final drop = job.drop;
    final target = collecting ? job.pickup : (drop ?? job.pickup);
    final phone = collecting ? job.pickupPhone : (job.dropPhone ?? '');

    return Container(
      key: Key('active-${job.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.primary)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(collecting ? Icons.storefront_rounded : Icons.local_shipping_rounded, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                collecting ? (job.isP2p ? 'Collect from the sender' : 'Collect from ${job.centerName ?? 'the center'}') : 'Deliver to ${job.buyerName ?? 'the farmer'}',
                style: text.titleSmall,
              ),
            ),
            Text(formatRupees(job.fee), style: text.titleMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text('${job.items.isEmpty ? '' : '${job.items} · '}${_kg(job.weightKg)} kg · ${job.distanceKm.toStringAsFixed(1)} km', style: text.bodyMedium),
          if (!collecting && drop != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text([if (drop.label.isNotEmpty) drop.label, if (job.dropVillage.isNotEmpty) job.dropVillage].join(', '), style: text.bodyMedium),
            if ((job.dropNote ?? '').isNotEmpty) Text('Note: ${job.dropNote}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          ],
          if (collecting && job.handoverCode != null) ...[
            AppSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text('Your handover code', style: text.labelMedium?.copyWith(color: colors.primary)),
                PopIn(
                  delay: const Duration(milliseconds: 200),
                  child: Text(job.handoverCode!, key: const Key('handover-code'), style: text.displaySmall?.copyWith(letterSpacing: 8, color: colors.primary, fontWeight: FontWeight.w800)),
                ),
                Text(
                  job.isP2p ? 'Give this code to the sender. They type it to hand the load over.' : 'Read this code to the operator at the counter. They type it, and the goods are yours.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              ]),
            ),
          ],
          AppSpacing.gapSm,
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.payments_outlined, size: 18, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(_cashWords(job), key: const Key('cash-words'), style: text.bodySmall)),
          ]),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(onPressed: () => openInMaps(context, latitude: target.latitude, longitude: target.longitude), icon: const Icon(Icons.directions_rounded, size: 18), label: const Text('Directions')),
              if (phone.isNotEmpty) OutlinedButton.icon(onPressed: () => callPhone(context, phone), icon: const Icon(Icons.call_rounded, size: 18), label: Text(collecting ? (job.isP2p ? 'Call sender' : 'Call') : 'Call ${job.isP2p ? 'receiver' : 'farmer'}')),
              if (!collecting) FilledButton.icon(key: const Key('enter-drop-code'), onPressed: busy ? null : onEnterCode, icon: const Icon(Icons.pin_outlined, size: 18), label: const Text('Enter the delivery code')),
              if (collecting) TextButton(key: const Key('give-back'), onPressed: busy ? null : onGiveBack, child: Text('Give it back', style: TextStyle(color: colors.danger))),
            ],
          ),
        ],
      ),
    );
  }

  static String _cashWords(PartnerJob j) {
    final cash = j.cashToCollect ?? j.fee;
    if (j.isP2p) {
      return j.collectFeeFrom == 'receiver'
          ? 'The receiver pays your fee, ${formatRupees(j.fee)}, in cash when you deliver.'
          : 'The sender pays your fee, ${formatRupees(j.fee)}, in cash when you collect the load.';
    }
    return 'Collect ${formatRupees(cash)} in cash from the buyer. Keep your fee ${formatRupees(j.fee)}; hand the rest, ${formatRupees(cash - j.fee)}, to the village center.';
  }
}

/// Asks for the 4-digit code the receiver reads out. Returns it, or null.
Future<String?> showDeliveryCodeDialog(BuildContext context, {String title = 'Enter the delivery code', String help = 'Ask the farmer for the 4-digit code in their app.', String action = 'Deliver'}) {
  return showDialog<String>(context: context, builder: (context) => _CodeDialog(title: title, help: help, action: action));
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({required this.title, required this.help, required this.action});

  final String title;
  final String help;
  final String action;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.help),
          AppSpacing.gapMd,
          TextField(
            key: const Key('code-field'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 8),
            decoration: const InputDecoration(counterText: ''),
            onChanged: (_) => setState(() {}),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(key: const Key('code-submit'), onPressed: _code.text.length == 4 ? () => Navigator.pop(context, _code.text) : null, child: Text(widget.action)),
        ],
      );
}
