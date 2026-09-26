import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khaadsetu_version1/core/network/api_client.dart';
import 'package:khaadsetu_version1/core/network/api_client_provider.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/operator/orders/offline/offline_sales.dart';
import 'package:shared_preferences/shared_preferences.dart';

PendingSale sale(String ref, {int qty = 2}) => PendingSale(
      clientRef: ref,
      soldAt: DateTime.utc(2026, 9, 27, 10),
      body: {'clientRef': ref, 'soldAt': '2026-09-27T10:00:00.000Z', 'customerName': 'Counter', 'paymentMode': 'cash', 'items': [{'productId': 'p1', 'quantity': qty, 'unitPrice': 450}]},
    );

ProviderContainer containerWith(MockClient mock) {
  final c = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(ApiClient(client: mock, deviceId: () async => 'op'))]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sales wait on the phone while there is no signal, then go out once, oldest first', () async {
    var online = false;
    final sent = <String>[];
    final c = containerWith(MockClient((req) async {
      if (!online) throw http.ClientException('no route');
      sent.add((jsonDecode(req.body) as Map)['clientRef'] as String);
      return http.Response(jsonEncode({'id': 'order-1'}), 201);
    }));
    final queue = c.read(offlineSalesProvider.notifier);
    await queue.add(sale('a'));
    await queue.add(sale('b'));
    expect(await queue.flush(), 0);
    expect(c.read(offlineSalesProvider), hasLength(2));

    online = true;
    expect(await queue.flush(), 2);
    expect(sent, ['a', 'b']);
    expect(c.read(offlineSalesProvider), isEmpty);
    expect(await queue.flush(), 0);
  });

  test('what waits survives the app being closed', () async {
    final c1 = containerWith(MockClient((_) async => throw http.ClientException('x')));
    await c1.read(offlineSalesProvider.notifier).add(sale('kept'));
    final c2 = containerWith(MockClient((_) async => throw http.ClientException('x')));
    c2.read(offlineSalesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c2.read(offlineSalesProvider).single.clientRef, 'kept');
    expect(c2.read(offlineSalesProvider).single.total, 900);
  });

  test('a sale the server refuses is marked and not retried, and the others still go', () async {
    final calls = <String>[];
    final c = containerWith(MockClient((req) async {
      final ref = (jsonDecode(req.body) as Map)['clientRef'] as String;
      calls.add(ref);
      return ref == 'bad' ? http.Response(jsonEncode({'error': 'Only 1 left in stock'}), 409) : http.Response(jsonEncode({'id': 'o'}), 201);
    }));
    final queue = c.read(offlineSalesProvider.notifier);
    await queue.add(sale('bad'));
    await queue.add(sale('good'));
    expect(await queue.flush(), 1);
    final left = c.read(offlineSalesProvider);
    expect(left.single.clientRef, 'bad');
    expect(left.single.problem, contains('stock'));
    calls.clear();
    await queue.flush();
    expect(calls, isEmpty);
    await queue.discard('bad');
    expect(c.read(offlineSalesProvider), isEmpty);
  });

  test('a server error keeps the sale for later instead of losing it', () async {
    final c = containerWith(MockClient((_) async => http.Response('{}', 503)));
    await c.read(offlineSalesProvider.notifier).add(sale('a'));
    expect(await c.read(offlineSalesProvider.notifier).flush(), 0);
    expect(c.read(offlineSalesProvider).single.problem, isNull);
  });

  testWidgets('the dashboard banner counts waiting sales and sends them on request', (tester) async {
    var online = false;
    final c = containerWith(MockClient((req) async {
      if (!online) throw http.ClientException('no route');
      return http.Response(jsonEncode({'id': 'o'}), 201);
    }));
    await c.read(offlineSalesProvider.notifier).add(sale('a'));
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: OfflineSalesBanner()))));
    await tester.pump();
    await tester.pump();
    expect(find.text('1 sale saved on this phone, waiting to be sent'), findsOneWidget);
    online = true;
    await tester.tap(find.byKey(const Key('offline-send')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });
}
