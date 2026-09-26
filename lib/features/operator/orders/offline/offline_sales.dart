import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A walk-in sale rung up with no signal, kept on the phone until it can be sent.
class PendingSale {
  const PendingSale({required this.clientRef, required this.soldAt, required this.body, this.problem});

  factory PendingSale.fromJson(Map<String, dynamic> j) => PendingSale(
        clientRef: '${j['clientRef']}',
        soldAt: DateTime.parse('${j['soldAt']}'),
        body: (j['body'] as Map).cast<String, dynamic>(),
        problem: j['problem'] as String?,
      );

  final String clientRef;
  final DateTime soldAt;

  /// The request exactly as it will be sent (it already carries the reference and the time).
  final Map<String, dynamic> body;

  /// Set when the server refused it (out of stock, say): it stays visible for the operator, and is not retried.
  final String? problem;

  double get total => [for (final i in (body['items'] as List)) (i as Map)['quantity'] * i['unitPrice']].fold<double>(0, (a, b) => a + (b as num));

  Map<String, dynamic> toJson() => {'clientRef': clientRef, 'soldAt': soldAt.toIso8601String(), 'body': body, 'problem': problem};

  PendingSale withProblem(String p) => PendingSale(clientRef: clientRef, soldAt: soldAt, body: body, problem: p);
}

const _key = 'offline_walk_in_sales';

/// The queue of offline sales. It survives the app being closed, and sending a sale twice is harmless: the server
/// recognises the reference and answers with the sale it already made.
class OfflineSalesQueue extends Notifier<List<PendingSale>> {
  bool _flushing = false;

  @override
  List<PendingSale> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) state = [for (final j in jsonDecode(raw) as List) PendingSale.fromJson((j as Map).cast<String, dynamic>())];
    } catch (_) {
      // Unreadable: start empty rather than crash the till.
    }
  }

  Future<void> _save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode([for (final s in state) s.toJson()]));
    } catch (_) {
      // The queue still lives in memory until the app closes.
    }
  }

  /// A fresh reference for a sale, made when it is rung up so that every later send of it is recognised.
  static String newRef() => 'sale-${const Uuid().v4()}';

  Future<void> add(PendingSale sale) async {
    state = [...state, sale];
    await _save();
  }

  Future<void> discard(String clientRef) async {
    state = [for (final s in state) if (s.clientRef != clientRef) s];
    await _save();
  }

  /// Sends what is waiting, oldest first. Stops at the first sign the network is still down. A sale the server refuses
  /// for its own reason is marked, and the rest go on.
  Future<int> flush() async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      final api = ref.read(apiClientProvider);
      for (final s in [...state.where((s) => s.problem == null)]) {
        try {
          await api.post('/v1/operator/orders/walk-in', body: s.body);
          state = [for (final x in state) if (x.clientRef != s.clientRef) x];
          sent += 1;
        } on ApiException catch (e) {
          if (e.isOffline || e.statusCode == 429 || (e.statusCode ?? 0) >= 500) break;
          state = [for (final x in state) x.clientRef == s.clientRef ? x.withProblem(e.message) : x];
        }
      }
      await _save();
    } finally {
      _flushing = false;
    }
    return sent;
  }
}

final offlineSalesProvider = NotifierProvider<OfflineSalesQueue, List<PendingSale>>(OfflineSalesQueue.new);

/// On the operator dashboard: tries to send waiting sales when it opens, when the app comes back to the front and every
/// minute, and says how many are waiting.
class OfflineSalesBanner extends ConsumerStatefulWidget {
  const OfflineSalesBanner({super.key});

  @override
  ConsumerState<OfflineSalesBanner> createState() => _OfflineSalesBannerState();
}

class _OfflineSalesBannerState extends ConsumerState<OfflineSalesBanner> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _send());
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _send();
  }

  Future<int> _send() async {
    if (!mounted || ref.read(offlineSalesProvider).every((s) => s.problem != null)) return 0;
    return ref.read(offlineSalesProvider.notifier).flush();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(offlineSalesProvider);
    if (queue.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final waiting = queue.where((s) => s.problem == null).length;
    final refused = queue.where((s) => s.problem != null).toList();
    return Container(
      key: const Key('offline-banner'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: colors.warning)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (waiting > 0)
          Row(children: [
            Icon(Icons.cloud_off_outlined, color: colors.warning),
            AppSpacing.gapSm,
            Expanded(child: Text('$waiting sale${waiting == 1 ? '' : 's'} saved on this phone, waiting to be sent', key: const Key('offline-waiting'))),
            TextButton(key: const Key('offline-send'), onPressed: _send, child: const Text('Send now')),
          ]),
        for (final s in refused)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.error_outline, color: colors.danger, size: 18),
              AppSpacing.gapSm,
              Expanded(child: Text('A saved sale of ₹${s.total.toStringAsFixed(0)} was refused: ${s.problem}', key: Key('offline-refused-${s.clientRef}'), style: TextStyle(color: colors.danger))),
              TextButton(onPressed: () => ref.read(offlineSalesProvider.notifier).discard(s.clientRef), child: const Text('Remove')),
            ]),
          ),
      ]),
    );
  }
}
