import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/resale_models.dart';
import '../farmer/sell_surplus_hub_screen.dart' show statusColor;
import '../resale_providers.dart';

final _listingProvider = FutureProvider.autoDispose.family<ResaleListing, String>((ref, id) async {
  final all = await ref.watch(resaleRepositoryProvider).queue(statuses: resaleEveryStatus);
  return all.firstWhere((l) => l.id == id);
});

final _photoProvider = FutureProvider.autoDispose.family<Uint8List, ({String id, String kind})>((ref, key) => ref.watch(resaleRepositoryProvider).photo(key.id, key.kind));

/// One farmer's listing at the village center: the photos, what was claimed, and what the center can do.
class ResaleReviewScreen extends ConsumerWidget {
  const ResaleReviewScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(_listingProvider(listingId));
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer listing')),
      body: ResponsiveScope(
        child: listing.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(_listingProvider(listingId))),
          data: (l) => _Body(listing: l),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.listing});

  final ResaleListing listing;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _run(Future<Object?> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(_listingProvider(widget.listing.id));
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(context: context, builder: (context) => const _ReasonDialog(title: 'Why is it not accepted?', hint: 'For example: bag is torn, batch number scratched off'));
    if (reason == null) return;
    await _run(() => ref.read(resaleRepositoryProvider).reject(widget.listing.id, reason), 'Rejected. Any buyer was told and refunded.');
  }

  Future<void> _askToBring() async {
    final note = await showDialog<String>(context: context, builder: (context) => const _ReasonDialog(title: 'Ask them to bring it in', hint: 'Optional note for the farmer', required: false));
    if (note == null) return;
    await _run(() => ref.read(resaleRepositoryProvider).requestInspection(widget.listing.id, note: note), 'The farmer was asked to bring it in.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final l = widget.listing;
    final color = statusColor(l.status, colors);
    final canInspect = [ResaleStatus.pendingVerification, ResaleStatus.inspectionRequired, ResaleStatus.live, ResaleStatus.awaitingHandover].contains(l.status);
    final canReject = l.status.isOpen && l.unitsSold == 0;
    return ListView(
      padding: context.pagePadding,
      children: [
        Text('${l.units} × ${l.productName}', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(spacing: AppSpacing.sm, runSpacing: 4, children: [
          _Chip(l.status.label, color),
          _Chip(l.verifiedPurchase ? 'Verified purchase' : 'No proof of purchase', l.verifiedPurchase ? colors.success : colors.warning),
          _Chip(l.channel == 'walk_in' ? 'Taken in at the counter' : 'Listed from the app', colors.info),
        ]),
        AppSpacing.gapMd,
        if (l.photoCount > 0)
          Row(children: [
            Expanded(child: _Photo(id: l.id, kind: 'front')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _Photo(id: l.id, kind: 'back')),
          ]),
        AppSpacing.gapMd,
        _Row('Seller', l.sellerDisplayName.isEmpty ? 'Farmer' : l.sellerDisplayName),
        if (l.sellerContact.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () => callPhone(context, l.sellerContact), icon: const Icon(Icons.call_rounded, size: 18), label: Text('Call ${l.sellerContact}')))),
        _Row('Asking', '${formatRupees(l.askingPrice)} each (platform price ${formatRupees(l.catalogPrice)})'),
        _Row('Suggested', formatRupees(l.suggestedPrice)),
        _Row('Condition', l.condition.label),
        _Row('Expires', l.expiryDate),
        if (l.mfgDate != null) _Row('Made on', l.mfgDate!),
        if (l.batchNumber.isNotEmpty) _Row('Batch', l.batchNumber),
        _Row('Payout', l.payoutMode.label),
        if (l.status == ResaleStatus.awaitingHandover && l.handoverDue != null) _Row('Bring by', '${l.handoverDue!.day}/${l.handoverDue!.month} ${l.handoverDue!.hour.toString().padLeft(2, '0')}:${l.handoverDue!.minute.toString().padLeft(2, '0')}'),
        if (l.unitsReserved > 0) _Row('Reserved by buyers', '${l.unitsReserved}'),
        if (l.unitsSold > 0) _Row('Sold', '${l.unitsSold}'),
        AppSpacing.gapLg,
        if (l.status == ResaleStatus.pendingVerification) ...[
          FilledButton.icon(key: const Key('preapprove'), onPressed: _busy ? null : () => _run(() => ref.read(resaleRepositoryProvider).preapprove(l.id), 'Approved. It is on sale now.'), icon: const Icon(Icons.check_circle_outline), label: const Text('Approve from the photos')),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(key: const Key('ask-to-bring'), onPressed: _busy ? null : _askToBring, icon: const Icon(Icons.inventory_2_outlined), label: const Text('Ask them to bring it in first')),
          const SizedBox(height: AppSpacing.xs),
          Text('Use this for high-value goods or a first-time seller.', style: text.labelSmall?.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (canInspect)
          FilledButton.icon(
            key: const Key('inspect'),
            style: l.status == ResaleStatus.pendingVerification ? FilledButton.styleFrom(backgroundColor: colors.secondary, foregroundColor: colors.onSecondary) : null,
            onPressed: _busy ? null : () async {
              await context.push(RoutePaths.operatorResaleInspect(l.id));
              ref.invalidate(_listingProvider(l.id));
            },
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(l.status == ResaleStatus.pendingVerification ? 'Goods are here: inspect now' : 'Inspect the goods'),
          ),
        if (canReject) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(key: const Key('reject'), onPressed: _busy ? null : _reject, icon: Icon(Icons.close_rounded, color: colors.danger), label: Text('Reject', style: TextStyle(color: colors.danger))),
        ],
        AppSpacing.gapLg,
      ],
    );
  }
}

class _Photo extends ConsumerWidget {
  const _Photo({required this.id, required this.kind});

  final String id;
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final photo = ref.watch(_photoProvider((id: id, kind: kind)));
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: photo.when(
          loading: () => const AppLoadingIndicator(),
          error: (_, _) => Center(child: Text('No $kind photo', style: Theme.of(context).textTheme.bodySmall)),
          data: (bytes) => GestureDetector(
            onTap: () => showDialog<void>(context: context, builder: (context) => Dialog(child: InteractiveViewer(child: Image.memory(bytes, errorBuilder: (_, _, _) => const Padding(padding: EdgeInsets.all(24), child: Icon(Icons.broken_image_outlined)))))),
            child: Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined))),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textMuted))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.hint, this.required = true});

  final String title;
  final String hint;
  final bool required;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = !widget.required || _controller.text.trim().length >= 3;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(key: const Key('reason-field'), controller: _controller, maxLines: 3, maxLength: 200, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: widget.hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('reason-ok'), onPressed: ok ? () => Navigator.pop(context, _controller.text.trim()) : null, child: const Text('Confirm')),
      ],
    );
  }
}
