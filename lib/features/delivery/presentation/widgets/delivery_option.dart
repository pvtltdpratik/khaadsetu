import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../domain/entities/delivery_models.dart';

/// A mobile number the server will accept (10 digits starting 6 to 9; +91 or 0 in front is fine).
bool isValidMobile(String raw) {
  final digits = raw.replaceAll(RegExp(r'[\s()-]+'), '').replaceFirst(RegExp(r'^\+?91'), '').replaceFirst(RegExp(r'^0'), '');
  return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
}

/// "Collect at the center" or "Bring it to my farm", and for a delivery what it
/// costs and who to call. The parent owns the choice and the quote so it can
/// drive the order button.
class DeliveryOption extends StatelessWidget {
  const DeliveryOption({
    super.key,
    required this.homeDelivery,
    required this.onChanged,
    required this.quote,
    required this.phone,
    required this.note,
    required this.placeLabel,
    this.enabled = true,
    this.onRetry,
  });

  final bool homeDelivery;
  final ValueChanged<bool> onChanged;
  final AsyncValue<DeliveryQuote> quote;
  final TextEditingController phone;
  final TextEditingController note;

  /// Where it will be brought, in words ("Shirur" or "your current location").
  final String placeLabel;
  final bool enabled;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          key: const Key('delivery-toggle'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, icon: Icon(Icons.storefront_rounded), label: Text('Collect')),
            ButtonSegment(value: true, icon: Icon(Icons.local_shipping_outlined), label: Text('Bring to my farm')),
          ],
          selected: {homeDelivery},
          onSelectionChanged: enabled ? (s) => onChanged(s.first) : null,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !homeDelivery
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        quote.when(
                          loading: () => const Row(children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text('Working out the delivery fee…')),
                          ]),
                          error: (err, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$err', style: text.bodyMedium?.copyWith(color: colors.danger)),
                            if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again')),
                          ]),
                          data: (q) => _Quote(quote: q, placeLabel: placeLabel),
                        ),
                        AppSpacing.gapMd,
                        TextField(
                          key: const Key('delivery-phone'),
                          controller: phone,
                          enabled: enabled,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Your mobile number', helperText: 'The delivery partner will call this number', prefixIcon: Icon(Icons.call_outlined)),
                        ),
                        AppSpacing.gapSm,
                        TextField(
                          key: const Key('delivery-note'),
                          controller: note,
                          enabled: enabled,
                          maxLength: 300,
                          decoration: const InputDecoration(labelText: 'Landmark (optional)', hintText: 'Near the temple, blue gate', prefixIcon: Icon(Icons.place_outlined)),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.quote, required this.placeLabel});

  final DeliveryQuote quote;
  final String placeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    if (!quote.available) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, color: colors.warning),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(quote.note, style: text.bodyMedium)),
      ]);
    }
    final kg = quote.weightKg == quote.weightKg.roundToDouble() ? quote.weightKg.toStringAsFixed(0) : quote.weightKg.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Delivery fee', style: text.titleSmall)),
            Text(formatRupees(quote.fee ?? 0), key: const Key('delivery-fee'), style: text.titleMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('$kg kg · about ${quote.roadKm.toStringAsFixed(1)} km from ${quote.centerName} to $placeLabel', style: text.bodySmall?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(quote.partnersFree > 0 ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded, size: 18, color: quote.partnersFree > 0 ? colors.success : colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(quote.note, style: text.bodySmall)),
        ]),
        if (quote.payment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.payments_outlined, size: 18, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(quote.payment, style: text.bodySmall)),
          ]),
        ],
      ],
    );
  }
}
