import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return ResponsiveScope(
      child: SafeArea(
        child: orderAsync.when(
          data: (order) => _OrderBody(order: order),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(
            message: '$err',
            onRetry: () => ref.invalidate(orderProvider(orderId)),
          ),
        ),
      ),
    );
  }
}

class _OrderBody extends ConsumerStatefulWidget {
  const _OrderBody({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends ConsumerState<_OrderBody> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  String? _otpError;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _markReady() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(ordersRepositoryProvider).markReadyForPickup(widget.order.id);
      ref.invalidate(orderProvider(widget.order.id));
      ref.invalidate(ordersProvider);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isSubmitting = true;
      _otpError = null;
    });
    try {
      await ref.read(ordersRepositoryProvider).verifyOtpAndComplete(
            widget.order.id,
            _otpController.text.trim(),
          );
      ref.invalidate(orderProvider(widget.order.id));
      ref.invalidate(ordersProvider);
    } catch (err) {
      setState(() => _otpError = '$err'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final order = widget.order;

    return ListView(
      padding: context.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(RoutePaths.operatorOrders),
            ),
            AppSpacing.gapSm,
            Expanded(child: Text('Order Details', style: Theme.of(context).textTheme.titleLarge)),
            OrderStatusBadge(status: order.status),
          ],
        ),
        AppSpacing.gapMd,
        Text(order.customerName, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            Icon(
              order.type == OrderType.appOrder ? Icons.smartphone_rounded : Icons.storefront_rounded,
              size: 14,
              color: colors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              order.type == OrderType.appOrder ? 'App order' : 'Walk-in sale',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        AppSpacing.gapLg,
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.productName} × ${item.quantity}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(formatRupees(item.subtotal), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            Expanded(child: Text('Total', style: Theme.of(context).textTheme.titleMedium)),
            Text(formatRupees(order.totalAmount), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        AppSpacing.gapLg,
        if (order.status == OrderStatus.pending)
          AppButton(
            label: 'Mark ready for pickup',
            icon: Icons.check_circle_outline_rounded,
            expand: true,
            isLoading: _isSubmitting,
            onPressed: _markReady,
          ),
        if (order.status == OrderStatus.readyForPickup) ...[
          Text('Verify pickup OTP', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ask the farmer for the OTP shown in their app to complete this handover.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          AppSpacing.gapSm,
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'Enter OTP',
              errorText: _otpError,
              counterText: '',
            ),
          ),
          AppSpacing.gapSm,
          AppButton(
            label: 'Verify & complete',
            icon: Icons.lock_open_rounded,
            expand: true,
            isLoading: _isSubmitting,
            onPressed: _verifyOtp,
          ),
        ],
      ],
    );
  }
}
