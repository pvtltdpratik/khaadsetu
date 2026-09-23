import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/nearby_center.dart';
import '../providers/centers_providers.dart';

/// The fallback for a phone with no GPS: pick your village from the list.
class VillagePickerScreen extends ConsumerStatefulWidget {
  const VillagePickerScreen({super.key});

  @override
  ConsumerState<VillagePickerScreen> createState() => _VillagePickerScreenState();
}

class _VillagePickerScreenState extends ConsumerState<VillagePickerScreen> {
  String _query = '';
  Timer? _debounce;
  late Future<List<Village>> _results = _search('');

  Future<List<Village>> _search(String q) => ref.read(centersRepositoryProvider).villages(q.trim());

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _results = _search(value);
      });
    });
  }

  Future<void> _pick(Village village) async {
    await ref.read(farmerLocationProvider.notifier).chooseVillage(village);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Choose your village')),
        body: SafeArea(
          child: ContentContainer(
            maxWidth: 600,
            child: Column(
              children: [
                TextField(
                  autofocus: false,
                  onChanged: _onChanged,
                  decoration: const InputDecoration(hintText: 'Search your village or district', prefixIcon: Icon(Icons.search_rounded), isDense: true),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: FutureBuilder<List<Village>>(
                    future: _results,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const AppLoadingIndicator();
                      if (snapshot.hasError) {
                        return AppErrorView(message: '${snapshot.error}', onRetry: () => setState(() => _results = _search(_query)));
                      }
                      final villages = snapshot.data!;
                      if (villages.isEmpty) {
                        return Center(child: Text('No village matches "$_query".', style: TextStyle(color: colors.textMuted)));
                      }
                      return ListView.separated(
                        itemCount: villages.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(villages[i].name),
                          subtitle: Text(villages[i].district),
                          onTap: () => _pick(villages[i]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
