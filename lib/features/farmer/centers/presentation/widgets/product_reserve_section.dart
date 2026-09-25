import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../../delivery/domain/entities/delivery_models.dart';
import '../../../../delivery/presentation/providers/delivery_providers.dart';
import '../../../../delivery/presentation/widgets/delivery_option.dart';
import '../../../../reviews/presentation/review_providers.dart';
import '../../../marketplace/domain/entities/product.dart';
import '../../../orders/domain/repositories/orders_repository.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../domain/availability_message.dart';
import '../../domain/entities/nearby_center.dart';
import '../providers/centers_providers.dart';
import '../screens/nearby_centers_screen.dart';
import 'location_banner.dart';

/// On a product page: how many, where it is available near you, and a button
/// to reserve it for pickup. The farmer can take the recommended center or pick
/// another; if someone else takes the last unit meanwhile they are offered the
/// next center instead of an error.
class ProductReserveSection extends ConsumerStatefulWidget {
  const ProductReserveSection({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductReserveSection> createState() => _ProductReserveSectionState();
}

class _ProductReserveSectionState extends ConsumerState<ProductReserveSection> {
  static const _maxQuantity = 99;

  int _quantity = 1;
  String? _pickedCenterId;
  bool _placing = false;

  /// A coupon the farmer earned by logging a harvest, taken off this order.
  String? _coupon;

  // Collect at the center (the default), or have a delivery partner bring it.
  bool _home = false;
  final _phone = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone.addListener(_changed);
  }

  void _changed() {
    if (_home && mounted) setState(() {});
  }

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Cart get _cart => Cart([CartLine(widget.product.id, _quantity)]);

  void _setQuantity(int q) => setState(() {
        _quantity = q.clamp(1, _maxQuantity);
        _pickedCenterId = null; // a different amount may fit a different center
      });

  Future<void> _chooseCenter() async {
    final id = await context.push<String>(RoutePaths.farmerCenters, extra: NearbyCentersArgs(cart: _cart, pick: true));
    if (id != null && mounted) setState(() => _pickedCenterId = id);
  }

  Future<String?> _askForAlternative(OutOfStockException out) {
    final available = out.alternatives.where((a) => a.inventoryStatus == InventoryStatus.all).toList();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Just went out of stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(available.isEmpty ? '${out.message}\n\nNo other center nearby has it right now.' : '${out.message}\n\nThese centers have it:'),
            for (final a in available)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                subtitle: Text('${a.village} · ${a.distanceKm.toStringAsFixed(1)} km away'),
                onTap: () => Navigator.pop(context, a.centerId),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(available.isEmpty ? 'OK' : 'Cancel'))],
      ),
    );
  }

  DeliveryAddress? _address(NearbyResult? result) {
    final where = result?.location;
    if (!_home || where == null) return null;
    return DeliveryAddress(
      latitude: where.latitude,
      longitude: where.longitude,
      phone: _phone.text.trim(),
      label: where.label ?? '',
      village: where.label ?? '',
      note: _note.text.trim(),
    );
  }

  /// "Use my 5% coupon": only shown when the farmer has an unused one.
  List<Widget> _couponPicker(AppColorTokens colors, TextTheme text) {
    final coupons = ref.watch(rewardsProvider).value?.usableCoupons ?? const [];
    if (coupons.isEmpty) return const [];
    return [
      AppSpacing.gapSm,
      Text('Use a coupon', style: text.labelMedium),
      Wrap(spacing: AppSpacing.sm, children: [
        for (final c in coupons)
          FilterChip(
            key: Key('coupon-${c.code}'),
            avatar: const Icon(Icons.local_offer_outlined, size: 16),
            label: Text('${c.percent.toStringAsFixed(0)}% off · ${c.code}'),
            selected: _coupon == c.code,
            onSelected: _placing ? null : (on) => setState(() => _coupon = on ? c.code : null),
          ),
      ]),
    ];
  }

  Future<void> _place(NearbyResult? result, String? centerId) async {
    setState(() => _placing = true);
    try {
      final order = await ref.read(ordersRepositoryProvider).place(
            items: _cart.lines,
            centerId: centerId,
            location: result?.location,
            delivery: _address(result),
            couponCode: _coupon,
          );
      if (_coupon != null) ref.invalidate(rewardsProvider);
      ref
        ..invalidate(myOrdersProvider)
        ..invalidate(nearbyCentersProvider);
      if (mounted) context.push(RoutePaths.farmerOrder(order.id));
    } on OutOfStockException catch (out) {
      ref.invalidate(nearbyCentersProvider);
      final alternative = await _askForAlternative(out);
      if (alternative != null && mounted) await _place(result, alternative);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final nearby = ref.watch(nearbyCentersProvider(_cart));
    final total = widget.product.priceInRupees * _quantity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collect from a village center', style: text.titleMedium),
          AppSpacing.gapSm,
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Fewer',
                onPressed: _quantity > 1 && !_placing ? () => _setQuantity(_quantity - 1) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(width: 48, child: Text('$_quantity', textAlign: TextAlign.center, style: text.titleLarge)),
              IconButton.outlined(
                tooltip: 'More',
                onPressed: _quantity < _maxQuantity && !_placing ? () => _setQuantity(_quantity + 1) : null,
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(formatRupees(total), style: text.titleMedium, textAlign: TextAlign.end)),
            ],
          ),
          AppSpacing.gapMd,
          nearby.when(
            loading: () => Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Checking stock near you…', style: text.bodyMedium)),
              ],
            ),
            error: (err, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$err', style: text.bodyMedium?.copyWith(color: colors.danger)),
                TextButton(onPressed: () => ref.invalidate(nearbyCentersProvider(_cart)), child: const Text('Try again')),
              ],
            ),
            data: (result) => result == null ? const LocationBanner() : _availability(context, result),
          ),
        ],
      ),
    );
  }

  Widget _availability(BuildContext context, NearbyResult result) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final message = describeAvailability(result, quantity: _quantity);

    // The farmer's own pick only stands while that center can still fill the order.
    final pickedOk = _pickedCenterId != null &&
        result.centers.any((c) => c.center.centerId == _pickedCenterId && c.inventory.status == InventoryStatus.all);
    final centerId = pickedOk ? _pickedCenterId : message.centerId;
    final selected = centerId == null ? null : result.centers.where((c) => c.center.centerId == centerId).firstOrNull;

    // For a home delivery the button waits for a quote that says yes, and a number to call.
    final quoteArgs = QuoteArgs(items: _cart.lines, location: result.location, centerId: centerId);
    final quote = _home && centerId != null ? ref.watch(deliveryQuoteProvider(quoteArgs)).value : null;
    final deliveryReady = !_home || (quote != null && quote.available && isValidMobile(_phone.text));

    final (icon, color) = switch (message.kind) {
      AvailabilityKind.readyForPickup => (Icons.check_circle_rounded, colors.success),
      AvailabilityKind.closedNow => (Icons.schedule_rounded, colors.warning),
      AvailabilityKind.elsewhere => (Icons.alt_route_rounded, colors.info),
      AvailabilityKind.partial => (Icons.warning_amber_rounded, colors.warning),
      AvailabilityKind.outOfStock => (Icons.remove_shopping_cart_outlined, colors.danger),
      AvailabilityKind.noCenters => (Icons.location_off_outlined, colors.textMuted),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message.text, style: text.bodyMedium)),
          ],
        ),
        if (selected != null) ...[
          AppSpacing.gapSm,
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.storefront_rounded, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('${selected.center.name} · ${selected.distanceKm.toStringAsFixed(1)} km · ${selected.hours.label}', style: text.bodySmall),
                ),
              ],
            ),
          ),
        ],
        if (centerId != null && message.canReserve) ...[
          AppSpacing.gapMd,
          DeliveryOption(
            homeDelivery: _home,
            onChanged: (v) => setState(() => _home = v),
            enabled: !_placing,
            phone: _phone,
            note: _note,
            placeLabel: result.location.label ?? 'your location',
            quote: _home ? ref.watch(deliveryQuoteProvider(quoteArgs)) : const AsyncLoading(),
            onRetry: () => ref.invalidate(deliveryQuoteProvider(quoteArgs)),
          ),
        ],
        ..._couponPicker(colors, text),
        AppSpacing.gapMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: centerId == null || _placing || !deliveryReady ? null : () => _place(result, centerId),
              icon: _placing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_home ? Icons.local_shipping_outlined : Icons.shopping_bag_outlined),
              label: Text(_home
                  ? (quote?.fee == null ? 'Order home delivery' : 'Order home delivery · ${formatRupees(quote!.fee!)}')
                  : message.kind == AvailabilityKind.closedNow
                      ? 'Reserve now, collect later'
                      : 'Reserve for pickup'),
            ),
            OutlinedButton.icon(
              onPressed: _placing ? null : (result.centers.length > 1 ? _chooseCenter : () => context.push(RoutePaths.farmerCenters, extra: NearbyCentersArgs(cart: _cart))),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(result.centers.length > 1 ? 'Choose a different center' : 'See centers'),
            ),
          ],
        ),
        if (!message.canReserve) ...[
          AppSpacing.gapMd,
          _NotifyMe(productId: widget.product.id, location: result.location),
        ],
        AppSpacing.gapSm,
        Text(
          _home
              ? 'Your items are held for you. You pay the goods and the delivery fee in cash when the delivery partner brings them.'
              : 'Reserving holds your items for 5 days. You pay at the center when you collect.',
          style: text.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

/// Shown when nothing nearby can fill the order: ask to be told when it can.
class _NotifyMe extends ConsumerStatefulWidget {
  const _NotifyMe({required this.productId, required this.location});

  final String productId;
  final FarmerLocation location;

  @override
  ConsumerState<_NotifyMe> createState() => _NotifyMeState();
}

class _NotifyMeState extends ConsumerState<_NotifyMe> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(centersRepositoryProvider);
      if (on) {
        await repo.turnNotifyMeOn(widget.productId, widget.location);
      } else {
        await repo.turnNotifyMeOff(widget.productId);
      }
      ref.invalidate(notifyMeProvider(widget.productId));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final on = ref.watch(notifyMeProvider(widget.productId)).value ?? false;
    if (on) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, size: 18, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text("We'll tell you when it's back in stock near you.", style: Theme.of(context).textTheme.bodySmall)),
            TextButton(onPressed: _busy ? null : () => _toggle(false), child: const Text('Cancel')),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _busy ? null : () => _toggle(true),
      icon: const Icon(Icons.notifications_none_rounded),
      label: const Text('Notify me when available'),
    );
  }
}
