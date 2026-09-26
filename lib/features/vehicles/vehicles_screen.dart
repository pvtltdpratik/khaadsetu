import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animation/pressable.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import 'vehicle_api.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

Tone vehicleTone(String status) => switch (status) { 'approved' => Tone.good, 'pending' => Tone.warn, 'rejected' || 'suspended' => Tone.bad, _ => Tone.neutral };

String vehicleStatusText(String status) => switch (status) {
      'approved' => 'Approved',
      'pending' => 'Being checked',
      'rejected' => 'Sent back',
      'suspended' => 'Paused by center',
      _ => 'Not sent yet',
    };

/// Every vehicle the farmer owns: its check, whether it is switched on for deliveries, and what is missing.
class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final vehicles = ref.watch(myVehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('vehicle-add'),
        onPressed: () async {
          final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const VehicleFormScreen()));
          ref.invalidate(myVehiclesProvider);
          if (id != null && context.mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(vehicleId: id)));
          ref.invalidate(myVehiclesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add a vehicle'),
      ),
      body: ResponsiveScope(
        child: vehicles.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myVehiclesProvider)),
          data: (list) => RefreshIndicator(
            onRefresh: () => ref.refresh(myVehiclesProvider.future),
            child: ListView(padding: context.pagePadding.copyWith(bottom: 96), children: [
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(children: [
                    Icon(Icons.local_shipping_outlined, size: 56, color: colors.textMuted),
                    AppSpacing.gapSm,
                    Text('No vehicle yet', key: const Key('vehicles-empty'), style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text('Add a bike, pickup, tractor or truck. After a village center checks its papers, you can take deliveries with it.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
                  ]),
                ),
              for (final (i, v) in list.indexed)
                KitCard(
                  index: i,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(vehicleId: v.str('id'))));
                    ref.invalidate(myVehiclesProvider);
                  },
                  child: Row(children: [
                    CircleAvatar(backgroundColor: colors.primaryContainer, child: Icon(Icons.local_shipping_outlined, color: colors.primary)),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.str('registrationNumber'), key: Key('vehicle-${v.str('id')}'), style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        Text([v.str('categoryLabel'), [v.str('company'), v.str('modelName')].where((s) => s.isNotEmpty).join(' '), 'up to ${v.int_('capacityKg')} kg'].where((s) => s.isNotEmpty).join('  ·  '), style: text.bodySmall?.copyWith(color: colors.textMuted)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          StatusPill(vehicleStatusText(v.str('status')), tone: vehicleTone(v.str('status'))),
                          if (v.str('status') == 'approved' && !v.flag('usable')) StatusPill(v.str('blockedReason', 'Papers need attention'), tone: Tone.warn),
                        ]),
                      ]),
                    ),
                    if (v.str('status') == 'approved')
                      Switch(
                        key: Key('vehicle-active-${v.str('id')}'),
                        value: v.flag('isActive'),
                        onChanged: (on) async {
                          try {
                            await ref.read(vehicleApiProvider).setActive(v.str('id'), on);
                          } catch (e) {
                            if (context.mounted) snack(context, '$e');
                          }
                          ref.invalidate(myVehiclesProvider);
                        },
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A small tappable row used on the delivery hub to open this screen.
class VehiclesTile extends StatelessWidget {
  const VehiclesTile({super.key});

  @override
  Widget build(BuildContext context) => Pressable(
        child: ListTile(
          key: const Key('open-vehicles'),
          leading: const Icon(Icons.local_shipping_outlined),
          title: const Text('My vehicles'),
          subtitle: const Text('Papers, photos and what each can carry'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VehiclesScreen())),
        ),
      );
}
