import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../farmer/centers/domain/entities/nearby_center.dart';
import '../../../farmer/centers/presentation/providers/centers_providers.dart';
import '../../domain/entities/delivery_models.dart';

/// A place chosen for a trip or a load: where I am now, or a village from the list.
/// Shows what is chosen; tapping opens a small sheet to change it.
class PlacePickerField extends ConsumerWidget {
  const PlacePickerField({super.key, required this.label, required this.value, required this.onChanged, this.icon = Icons.place_outlined});

  final String label;
  final GeoPoint? value;
  final ValueChanged<GeoPoint> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showModalBottomSheet<GeoPoint>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _PlaceSheet());
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: const Icon(Icons.expand_more_rounded)),
        child: Text(
          value == null ? 'Choose a place' : (value!.label.isEmpty ? 'Pinned location' : value!.label),
          style: text.bodyLarge?.copyWith(color: value == null ? colors.textMuted : null),
        ),
      ),
    );
  }
}

class _PlaceSheet extends ConsumerStatefulWidget {
  const _PlaceSheet();

  @override
  ConsumerState<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<_PlaceSheet> {
  Timer? _debounce;
  late Future<List<Village>> _results = ref.read(centersRepositoryProvider).villages('');

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _results = ref.read(centersRepositoryProvider).villages(value.trim()));
    });
  }

  Future<void> _useMyLocation() async {
    final here = await ref.read(farmerLocationProvider.future);
    if (!mounted) return;
    if (here == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We could not find where you are. Search for a village instead.')));
      return;
    }
    Navigator.pop(context, GeoPoint(latitude: here.latitude, longitude: here.longitude, label: here.label ?? 'My location'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            ListTile(key: const Key('use-my-location'), leading: Icon(Icons.my_location_rounded, color: colors.primary), title: const Text('Use my location'), onTap: _useMyLocation),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(key: const Key('village-search'), onChanged: _onChanged, decoration: const InputDecoration(hintText: 'Search a village', prefixIcon: Icon(Icons.search_rounded))),
            ),
            Expanded(
              child: FutureBuilder<List<Village>>(
                future: _results,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                  final villages = snapshot.data ?? const [];
                  if (villages.isEmpty) return const Center(child: Text('No village found'));
                  return ListView.builder(
                    itemCount: villages.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(villages[i].name),
                      subtitle: Text(villages[i].district),
                      onTap: () => Navigator.pop(context, GeoPoint(latitude: villages[i].latitude, longitude: villages[i].longitude, label: villages[i].name)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
