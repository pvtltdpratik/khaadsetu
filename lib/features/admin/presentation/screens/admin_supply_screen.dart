import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../operator/surplus/domain/entities/surplus_lot.dart';
import '../../domain/entities/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

enum SupplyTab { restock, discrepancies, surplus }

SupplyTab supplyTabFromQuery(String? raw) => switch (raw) {
      'discrepancies' => SupplyTab.discrepancies,
      'surplus' => SupplyTab.surplus,
      _ => SupplyTab.restock,
    };

/// The supply desk: restock requests to approve and deliver, and delivery
/// reports from operators to review.
class AdminSupplyScreen extends ConsumerStatefulWidget {
  const AdminSupplyScreen({super.key, this.initialTab = SupplyTab.restock});

  final SupplyTab initialTab;

  @override
  ConsumerState<AdminSupplyScreen> createState() => _AdminSupplyScreenState();
}

class _AdminSupplyScreenState extends ConsumerState<AdminSupplyScreen> {
  late SupplyTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Supply', style: Theme.of(context).textTheme.headlineSmall)),
                    if (!context.breakpoint.isTabletUp) const SignOutButton(),
                  ],
                ),
                AppSpacing.gapMd,
                SegmentedButton<SupplyTab>(
                  segments: const [
                    ButtonSegment(value: SupplyTab.restock, label: Text('Restock requests'), icon: Icon(Icons.local_shipping_outlined)),
                    ButtonSegment(value: SupplyTab.discrepancies, label: Text('Delivery reports'), icon: Icon(Icons.fact_check_outlined)),
                    ButtonSegment(value: SupplyTab.surplus, label: Text('Surplus'), icon: Icon(Icons.sell_outlined)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
                AppSpacing.gapMd,
                switch (_tab) {
                  SupplyTab.restock => const _RestockList(),
                  SupplyTab.discrepancies => const _DiscrepancyList(),
                  SupplyTab.surplus => const _SurplusList(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs a supply action, then refreshes the panel and reports the outcome.
Future<void> _perform(BuildContext context, WidgetRef ref, Future<void> Function() action, String done) async {
  try {
    await action();
    refreshAdminData(ref);
    if (context.mounted) showMessage(context, done);
  } catch (err) {
    if (context.mounted) showMessage(context, '$err');
  }
}

String _ago(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}

// ---------------------------------------------------------------------------
// Restock requests
// ---------------------------------------------------------------------------

class _RestockList extends ConsumerStatefulWidget {
  const _RestockList();

  @override
  ConsumerState<_RestockList> createState() => _RestockListState();
}

class _RestockListState extends ConsumerState<_RestockList> {
  // Pending first: that is the queue an admin came here to clear.
  RestockStatus? _status = RestockStatus.pending;

  static const _labels = <RestockStatus?, String>{
    RestockStatus.pending: 'Pending',
    RestockStatus.approved: 'On its way',
    RestockStatus.fulfilled: 'Delivered',
    null: 'All',
  };

  Future<void> _advance(RestockRequest r) async {
    final to = r.status.next;
    if (to == null) return;
    final approving = to == RestockStatus.approved;
    final ok = await confirmAction(
      context,
      title: approving ? 'Approve this restock?' : 'Mark as delivered?',
      message: approving
          ? '${r.quantity} × ${r.productName} for ${r.centerName}. The operator is told it is on its way and sees it as incoming stock.'
          : '${r.quantity} × ${r.productName} reached ${r.centerName}. The operator is asked to confirm the stock when it arrives.',
      confirmLabel: approving ? 'Approve' : 'Mark delivered',
    );
    if (ok == null || !mounted) return;
    await _perform(context, ref, () => ref.read(adminRepositoryProvider).advanceRestock(r.id, to), approving ? 'Restock approved' : 'Marked as delivered');
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminRestockProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterChips<RestockStatus>(options: _labels, selected: _status, onChanged: (s) => setState(() => _status = s)),
        AppSpacing.gapMd,
        requests.when(
          data: (list) => list.isEmpty
              ? _Empty(icon: Icons.local_shipping_outlined, text: _status == RestockStatus.pending ? 'No restock requests are waiting.' : 'No restock requests here.')
              : Column(children: [for (final (i, r) in list.indexed) FadeSlideIn(key: ValueKey(r.id), index: i, child: _RestockCard(request: r, onAdvance: () => _advance(r)))]),
          loading: () => const SizedBox(height: 160, child: AppLoadingIndicator()),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminRestockProvider)),
        ),
      ],
    );
  }
}

class _RestockCard extends StatelessWidget {
  const _RestockCard({required this.request, required this.onAdvance});

  final RestockRequest request;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final r = request;
    final (label, color) = switch (r.status) {
      RestockStatus.pending => ('Pending', colors.warning),
      RestockStatus.approved => ('On its way', colors.info),
      RestockStatus.fulfilled => ('Delivered', colors.success),
    };
    final next = r.status.next;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${r.quantity} × ${r.productName}', style: text.titleSmall)),
              StatusBadge(label: label, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text('${r.centerName}${r.requestedDate == null ? '' : ' · requested ${_ago(r.requestedDate)}'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          if (next != null) ...[
            AppSpacing.gapSm,
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onAdvance,
                child: Text(next == RestockStatus.approved ? 'Approve' : 'Mark delivered'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery reports
// ---------------------------------------------------------------------------

class _DiscrepancyList extends ConsumerStatefulWidget {
  const _DiscrepancyList();

  @override
  ConsumerState<_DiscrepancyList> createState() => _DiscrepancyListState();
}

class _DiscrepancyListState extends ConsumerState<_DiscrepancyList> {
  bool _resolved = false;

  Future<void> _resolve(StockDiscrepancy d) async {
    final note = await confirmAction(
      context,
      title: 'Mark as reviewed?',
      message: '${d.centerName} reported ${d.received} of ${d.expected} ${d.productName}. Your note is sent to the operator.',
      confirmLabel: 'Mark reviewed',
      askReason: true,
    );
    if (note == null || !mounted) return;
    await _perform(context, ref, () => ref.read(adminRepositoryProvider).resolveDiscrepancy(d.id, note: note), 'Report marked as reviewed');
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(adminDiscrepanciesProvider(_resolved));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterChips<bool>(
          options: const {false: 'To review', true: 'Reviewed'},
          selected: _resolved,
          onChanged: (v) => setState(() => _resolved = v ?? false),
        ),
        AppSpacing.gapMd,
        reports.when(
          data: (list) => list.isEmpty
              ? _Empty(icon: Icons.fact_check_outlined, text: _resolved ? 'No reviewed reports yet.' : 'No delivery reports to review.')
              : Column(children: [for (final (i, d) in list.indexed) FadeSlideIn(key: ValueKey(d.id), index: i, child: _DiscrepancyCard(report: d, onResolve: () => _resolve(d)))]),
          loading: () => const SizedBox(height: 160, child: AppLoadingIndicator()),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminDiscrepanciesProvider)),
        ),
      ],
    );
  }
}

class _DiscrepancyCard extends StatelessWidget {
  const _DiscrepancyCard({required this.report, required this.onResolve});

  final StockDiscrepancy report;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final d = report;
    final gap = d.shortfall;
    final gapText = gap > 0 ? '$gap short' : gap < 0 ? '${-gap} extra' : 'matches';
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(d.productName, style: text.titleSmall)),
              StatusBadge(
                label: d.resolved ? 'Reviewed' : gapText,
                color: d.resolved ? colors.success : colors.warning,
                icon: d.resolved ? Icons.check_circle_outline_rounded : Icons.report_gmailerrorred_rounded,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('${d.centerName}${d.createdAt == null ? '' : ' · ${_ago(d.createdAt)}'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          AppSpacing.gapSm,
          Text('Expected ${d.expected}, received ${d.received}${d.resolved ? ' ($gapText)' : ''}', style: text.bodyMedium),
          if (d.note.isNotEmpty) Text('Operator: ${d.note}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          if (d.resolved && d.resolutionNote.isNotEmpty) Text('Your note: ${d.resolutionNote}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          if (!d.resolved) ...[
            AppSpacing.gapSm,
            Align(alignment: Alignment.centerRight, child: FilledButton.tonal(onPressed: onResolve, child: const Text('Mark reviewed'))),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surplus
// ---------------------------------------------------------------------------

class _SurplusList extends ConsumerStatefulWidget {
  const _SurplusList();

  @override
  ConsumerState<_SurplusList> createState() => _SurplusListState();
}

class _SurplusListState extends ConsumerState<_SurplusList> {
  bool _showEnded = false;

  Future<void> _withdraw(AdminSurplusLot item) async {
    final reason = await confirmAction(
      context,
      title: 'Withdraw this offer?',
      message: '${item.lot.productName} at ${item.centerName} comes off sale. The operator is told, and unsold units go back to their shelf if they came from it.',
      confirmLabel: 'Withdraw',
      destructive: true,
      askReason: true,
    );
    if (reason == null || !mounted) return;
    await _perform(context, ref, () => ref.read(adminRepositoryProvider).withdrawSurplus(item.lot.id, reason: reason), 'Offer withdrawn');
  }

  @override
  Widget build(BuildContext context) {
    final lots = ref.watch(adminSurplusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        lots.when(
          data: (all) {
            final onSale = all.where((l) => l.lot.isOnSale).toList();
            final ended = all.where((l) => !l.lot.isOnSale).toList();
            final shown = _showEnded ? ended : onSale;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterChips<bool>(
                  options: {false: 'On sale (${onSale.length})', true: 'Ended (${ended.length})'},
                  selected: _showEnded,
                  onChanged: (v) => setState(() => _showEnded = v ?? false),
                ),
                AppSpacing.gapMd,
                if (shown.isEmpty)
                  _Empty(icon: Icons.sell_outlined, text: _showEnded ? 'No ended surplus offers.' : 'No surplus is on sale right now.')
                else
                  Column(children: [for (final (i, item) in shown.indexed) FadeSlideIn(key: ValueKey(item.lot.id), index: i, child: _SurplusCard(item: item, onWithdraw: () => _withdraw(item)))]),
              ],
            );
          },
          loading: () => const SizedBox(height: 160, child: AppLoadingIndicator()),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminSurplusProvider)),
        ),
      ],
    );
  }
}

class _SurplusCard extends StatelessWidget {
  const _SurplusCard({required this.item, required this.onWithdraw});

  final AdminSurplusLot item;
  final VoidCallback onWithdraw;

  static String _money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final lot = item.lot;
    final (label, color) = switch (lot.status) {
      SurplusStatus.active => ('On sale', colors.success),
      SurplusStatus.soldOut => ('Sold out', colors.textMuted),
      SurplusStatus.expired => ('Expired', colors.danger),
      SurplusStatus.withdrawn => ('Withdrawn', colors.textMuted),
    };
    final best = lot.bestBefore;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(lot.productName, style: text.titleSmall)),
              StatusBadge(label: label, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text('${item.centerName}${item.village.isEmpty ? '' : ', ${item.village}'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          AppSpacing.gapSm,
          Text('Rs ${_money(lot.unitPrice)} (regular Rs ${_money(lot.catalogPrice)}, ${lot.discountPercent}% off)', style: text.bodyMedium),
          Text(
            '${lot.available} available${lot.reserved > 0 ? ', ${lot.reserved} held' : ''} · ${lot.condition.label}${best == null ? '' : ' · best before ${best.day}/${best.month}/${best.year}'}',
            style: text.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (lot.note.isNotEmpty) Text(lot.note, style: text.bodySmall?.copyWith(color: colors.textMuted)),
          if (lot.isOnSale) ...[
            AppSpacing.gapSm,
            Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: onWithdraw, child: const Text('Withdraw'))),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: child,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: colors.textMuted),
            AppSpacing.gapSm,
            Text(text, style: TextStyle(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
