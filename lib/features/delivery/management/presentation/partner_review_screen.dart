import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';
import '../domain/management_models.dart';
import 'management_providers.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// One application: who, what vehicle, the two papers to look at, and the
/// decision. Approving, rejecting, suspending and reactivating all tell the farmer.
class PartnerReviewScreen extends ConsumerStatefulWidget {
  const PartnerReviewScreen({super.key, required this.scope, required this.userId});

  final ManagementScope scope;
  final String userId;

  @override
  ConsumerState<PartnerReviewScreen> createState() => _PartnerReviewScreenState();
}

class _PartnerReviewScreenState extends ConsumerState<PartnerReviewScreen> {
  bool _busy = false;

  PartnerKey get _key => PartnerKey(widget.scope, widget.userId);

  Future<void> _decide(ReviewAction action) async {
    String? note;
    if (action.needsReason) {
      note = await _askReason(action);
      if (note == null || !mounted) return;
    } else if (action == ReviewAction.approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve this partner?'),
          content: const Text('Have you looked at the licence and the RC, and do the names and the vehicle match? They will be able to take deliveries straight away.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
            FilledButton(key: const Key('confirm-approve'), onPressed: () => Navigator.pop(context, true), child: const Text('Approve')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(managementRepositoryProvider(widget.scope)).review(widget.userId, action, note: note);
      ref.invalidate(managedPartnerProvider(_key));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(ReviewAction action) => showDialog<String>(context: context, builder: (_) => _ReasonDialog(action: action));

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(managedPartnerProvider(_key));
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Delivery partner')),
        body: SafeArea(
          child: partner.when(
            skipLoadingOnReload: true,
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(managedPartnerProvider(_key))),
            data: (p) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [ContentContainer(maxWidth: 720, child: _Body(partner: p, scope: widget.scope, busy: _busy, onDecide: _decide))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks why, since the farmer is told. A dialog of its own so it owns its text box.
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.action});

  final ReviewAction action;

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
    final reject = widget.action == ReviewAction.reject;
    return AlertDialog(
      title: Text(reject ? 'Turn this application down' : 'Pause this partner'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(reject ? 'Tell them what is wrong, so they can fix it and apply again.' : 'They will not get jobs until you reactivate them. Say why.'),
        AppSpacing.gapSm,
        TextField(key: const Key('reason-field'), controller: _controller, maxLength: 300, maxLines: 3, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Reason')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('reason-submit'), onPressed: _controller.text.trim().length < 3 ? null : () => Navigator.pop(context, _controller.text.trim()), child: Text(reject ? 'Turn down' : 'Pause')),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.partner, required this.scope, required this.busy, required this.onDecide});

  final PartnerApplication partner;
  final ManagementScope scope;
  final bool busy;
  final ValueChanged<ReviewAction> onDecide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final p = partner;
    final days = [for (final d in p.days) if (d >= 0 && d < 7) _dayNames[d]].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(p.name, style: text.headlineSmall),
        Text([if (p.village.isNotEmpty) p.village, if (p.phone.isNotEmpty) p.phone].join(' · '), style: text.bodyMedium?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        if (p.phone.isNotEmpty) Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () => callPhone(context, p.phone), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call'))),
        AppSpacing.gapMd,
        _Section(title: 'Status', child: Text(switch (p.status) {
          PartnerStatus.pending => 'Waiting for your decision',
          PartnerStatus.approved => 'Approved${p.online ? ' · free now' : ''}',
          PartnerStatus.suspended => 'Paused',
          PartnerStatus.rejected => 'Turned down${(p.rejectionReason ?? '').isEmpty ? '' : ': ${p.rejectionReason}'}',
          _ => 'Not sent yet',
        }, key: const Key('partner-status'))),
        _Section(
          title: 'Vehicle',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.vehicleType?.label ?? 'Not given'} · ${p.vehicleNumber.isEmpty ? 'no number' : p.vehicleNumber}', key: const Key('partner-vehicle')),
            Text('Carries up to ${p.capacityKg ?? '?'} kg'),
            Text('Goes up to ${p.maxDistanceKm} km · ${days.isEmpty ? 'no days set' : days} · ${p.freeFrom} to ${p.freeUntil}'),
            if (p.deliveriesDone > 0 || p.ratingCount > 0) Text('${p.deliveriesDone} deliveries${p.ratingCount > 0 ? ' · ★ ${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount})' : ''}'),
          ]),
        ),
        _Section(
          title: 'Papers',
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _DocumentView(scope: scope, userId: p.userId, kind: 'licence', title: 'Driving licence', present: p.licence != null)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _DocumentView(scope: scope, userId: p.userId, kind: 'rc', title: 'Vehicle RC', present: p.rc != null)),
          ]),
        ),
        if (p.reviewCenterName != null) _Section(title: 'Checking center', child: Text(p.reviewCenterName!)),
        AppSpacing.gapSm,
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          if (p.status == PartnerStatus.pending) ...[
            FilledButton.icon(key: const Key('approve'), onPressed: busy ? null : () => onDecide(ReviewAction.approve), icon: const Icon(Icons.verified_outlined), label: const Text('Approve')),
            OutlinedButton.icon(key: const Key('reject'), onPressed: busy ? null : () => onDecide(ReviewAction.reject), icon: Icon(Icons.close_rounded, color: colors.danger), label: Text('Turn down', style: TextStyle(color: colors.danger))),
          ],
          if (p.status == PartnerStatus.approved)
            OutlinedButton.icon(key: const Key('suspend'), onPressed: busy ? null : () => onDecide(ReviewAction.suspend), icon: Icon(Icons.pause_circle_outline_rounded, color: colors.danger), label: Text('Pause this partner', style: TextStyle(color: colors.danger))),
          if (p.status == PartnerStatus.suspended)
            FilledButton.icon(key: const Key('reactivate'), onPressed: busy ? null : () => onDecide(ReviewAction.reactivate), icon: const Icon(Icons.play_circle_outline_rounded), label: const Text('Let them deliver again')),
        ]),
        if (p.events.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text('History', style: text.titleMedium),
          AppSpacing.gapSm,
          for (final e in p.events)
            ListTile(
              key: Key('event-${e.action}-${e.createdAt.millisecondsSinceEpoch}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text('${_words(e.action)}${e.note.isEmpty ? '' : ': ${e.note}'}'),
              subtitle: Text('${formatDay(e.createdAt)} · ${e.actorRole}'),
            ),
        ],
      ],
    );
  }

  static String _words(String action) => switch (action) {
        'submitted' => 'Sent for checking',
        'resubmitted' => 'Changed details, sent again',
        'approve' || 'approved' => 'Approved',
        'reject' || 'rejected' => 'Turned down',
        'suspend' || 'suspended' => 'Paused',
        'reactivate' || 'reactivated' => 'Let them deliver again',
        _ => action,
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.textMuted)),
        const SizedBox(height: AppSpacing.xs),
        child,
      ]),
    );
  }
}

/// A paper's photo, fetched when the page opens. Tap it to see it big.
class _DocumentView extends ConsumerWidget {
  const _DocumentView({required this.scope, required this.userId, required this.kind, required this.title, required this.present});

  final ManagementScope scope;
  final String userId;
  final String kind;
  final String title;
  final bool present;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        if (!present)
          Container(key: Key('missing-$kind'), height: 110, alignment: Alignment.center, decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(10)), child: const Text('Not uploaded'))
        else
          ref.watch(managedDocumentProvider(DocumentKey(scope, userId, kind))).when(
            loading: () => Container(height: 110, alignment: Alignment.center, child: const CircularProgressIndicator()),
            error: (err, _) => Container(height: 110, alignment: Alignment.center, child: Text('$err', textAlign: TextAlign.center)),
            data: (bytes) {
              // A PDF cannot be drawn here: say so, rather than showing a broken picture.
              final isPdf = bytes.length > 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
              if (isPdf) return Container(key: Key('pdf-$kind'), height: 110, alignment: Alignment.center, decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(10)), child: const Text('A PDF was uploaded'));
              return GestureDetector(
                key: Key('doc-image-$kind'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.all(AppSpacing.md),
                    child: Stack(children: [
                      InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
                      Positioned(top: 4, right: 4, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))),
                    ]),
                  ),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(height: 110, alignment: Alignment.center, child: const Text('Could not show this photo')))),
              );
            },
          ),
      ],
    );
  }
}
