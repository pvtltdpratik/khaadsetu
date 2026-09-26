import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/invoice_models.dart';

/// "Paid", "Unpaid", "Part paid", "Refunded" or "Cancelled" in the colour that says it at a glance.
class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = invoice.isCancelled ? 'cancelled' : invoice.paymentStatus;
    final color = switch (status) {
      'paid' => colors.success,
      'unpaid' => colors.danger,
      'partial' => colors.warning,
      _ => colors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(paymentStatusLabels[status] ?? status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
