import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/auth/session_profile.dart';
import 'package:khaadsetu_version1/core/push/push_service.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/domain/entities/app_notification.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/presentation/notification_navigation.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/presentation/providers/notifications_providers.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/presentation/screens/notifications_screen.dart';
import 'package:khaadsetu_version1/features/push/domain/push_models.dart';
import 'package:khaadsetu_version1/features/push/domain/push_repository.dart';
import 'package:khaadsetu_version1/features/push/presentation/notification_settings_screen.dart';
import 'package:khaadsetu_version1/features/push/presentation/push_providers.dart';

import 'support/operator_fakes.dart';

class FakePushRepository implements PushRepository {
  FakePushRepository({this.current = const NotificationSettings()});

  NotificationSettings current;
  final registered = <({String token, String app})>[];
  final unregistered = <String>[];
  final channelChanges = <(String, bool)>[];
  final quietChanges = <QuietHours>[];
  Object? registerError;

  @override
  Future<void> registerDevice({required String token, required String app}) async {
    if (registerError != null) throw registerError!;
    registered.add((token: token, app: app));
  }

  @override
  Future<void> unregisterDevice(String token) async => unregistered.add(token);

  @override
  Future<NotificationSettings> settings() async => current;

  @override
  Future<void> setChannel(String channel, {required bool enabled}) async {
    channelChanges.add((channel, enabled));
    current = NotificationSettings(off: enabled ? (current.off.toSet()..remove(channel)) : {...current.off, channel}, quiet: current.quiet);
  }

  @override
  Future<void> setQuietHours(QuietHours quiet) async {
    quietChanges.add(quiet);
    current = NotificationSettings(off: current.off, quiet: quiet);
  }
}

class FakePushService implements PushService {
  Future<void> Function(String token)? onToken;
  PushOpened? onOpened;
  bool started = false;
  bool stopped = false;

  @override
  bool get available => true;

  @override
  Future<void> start({required Future<void> Function(String token) onToken, required PushOpened onOpened}) async {
    started = true;
    this.onToken = onToken;
    this.onOpened = onOpened;
    await onToken('tok-1');
  }

  @override
  Future<void> stop() async => stopped = true;
}

AppNotification note(String id, NotificationType type, String channel, {bool read = false, String? refId}) =>
    AppNotification(id: id, type: type, title: 'Title $id', body: 'Body $id', createdAt: DateTime(2026, 9, 26, 10), isRead: read, refId: refId ?? 'ref-$id', channel: channel);

SessionProfile me(AppRole role) => SessionProfile(userId: 'u', email: 'e', name: 'n', role: role, requestedRole: role.name, status: 'active');

void main() {
  group('reading what the server sends', () {
    test('categories off are the ones with enabled false, and quiet hours default sensibly', () {
      final s = NotificationSettings.fromJson({
        'channels': [
          {'channel': 'orders', 'enabled': true},
          {'channel': 'community', 'enabled': false},
        ],
        'quietHours': {'enabled': true, 'from': '21:30', 'until': '05:45'},
      });
      expect(s.isOn('orders'), isTrue);
      expect(s.isOn('community'), isFalse);
      expect(s.quiet, const QuietHours(enabled: true, from: '21:30', until: '05:45'));
      expect(NotificationSettings.fromJson(const {}).quiet, const QuietHours());
    });
  });

  group('settings screen', () {
    Future<FakePushRepository> pump(WidgetTester tester, {NotificationSettings? start}) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakePushRepository(current: start ?? const NotificationSettings());
      await tester.pumpWidget(ProviderScope(
        overrides: [pushRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(theme: AppTheme.light, home: const NotificationSettingsScreen()),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('lists every category, and switching one off is sent to the server', (tester) async {
      final repo = await pump(tester);
      for (final c in pushChannels) {
        expect(find.byKey(Key('channel-${c.id}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('channel-community')));
      await tester.pumpAndSettle();
      expect(repo.channelChanges, [('community', false)]);
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('channel-community'))).value, isFalse);
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('channel-orders'))).value, isTrue);
    });

    testWidgets('quiet hours: the times only appear once it is on, and turning it on is saved', (tester) async {
      final repo = await pump(tester);
      expect(find.byKey(const Key('quiet-from')), findsNothing);
      await tester.tap(find.byKey(const Key('quiet-enabled')));
      await tester.pumpAndSettle();
      expect(repo.quietChanges.single.enabled, isTrue);
      expect(find.text('From 22:00'), findsOneWidget);
      expect(find.text('Until 06:00'), findsOneWidget);
    });

    testWidgets('a saved setting is shown as it was left', (tester) async {
      await pump(tester, start: const NotificationSettings(off: {'deliveries'}, quiet: QuietHours(enabled: true, from: '20:15', until: '07:00')));
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('channel-deliveries'))).value, isFalse);
      expect(find.text('From 20:15'), findsOneWidget);
    });
  });

  group('registering this phone', () {
    Future<({ProviderContainer container, FakePushRepository repo, FakePushService service})> setUp() async {
      final repo = FakePushRepository();
      final service = FakePushService();
      final container = ProviderContainer(overrides: [pushRepositoryProvider.overrideWithValue(repo), pushServiceProvider.overrideWithValue(service)]);
      addTearDown(container.dispose);
      return (container: container, repo: repo, service: service);
    }

    test('starting hands the token to the server, once, under this app\'s name', () async {
      final t = await setUp();
      final registration = t.container.read(pushRegistrationProvider);
      await registration.start(onOpened: (_) {});
      await registration.start(onOpened: (_) {});
      expect(t.repo.registered.length, 1, reason: 'a second start does nothing');
      expect(t.repo.registered.single.token, 'tok-1');
      expect(t.repo.registered.single.app, 'app', reason: 'the default flavor in tests');
    });

    test('a token that changes is registered again', () async {
      final t = await setUp();
      await t.container.read(pushRegistrationProvider).start(onOpened: (_) {});
      await t.service.onToken!('tok-2');
      expect(t.repo.registered.map((r) => r.token), ['tok-1', 'tok-2']);
    });

    test('a server that is unreachable does not stop the app', () async {
      final t = await setUp();
      t.repo.registerError = 'offline';
      await t.container.read(pushRegistrationProvider).start(onOpened: (_) {});
      expect(t.service.started, isTrue);
    });

    test('signing out takes the phone off the list and stops listening', () async {
      final t = await setUp();
      final registration = t.container.read(pushRegistrationProvider);
      await registration.start(onOpened: (_) {});
      await registration.forget();
      expect(t.repo.unregistered, ['tok-1']);
      expect(t.service.stopped, isTrue);
      await registration.start(onOpened: (_) {});
      expect(t.repo.registered.length, 2, reason: 'the next person to sign in registers it again');
    });

    testWidgets('the wrapper starts push as soon as somebody is signed in, and not before', (tester) async {
      final t = await setUp();
      final signedIn = ValueNotifier<bool>(false);
      addTearDown(signedIn.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: ProviderContainer(overrides: [
          pushRepositoryProvider.overrideWithValue(t.repo),
          pushServiceProvider.overrideWithValue(t.service),
          sessionProfileProvider.overrideWith((ref) async => null),
        ]),
        child: MaterialApp(home: PushRegistrar(onOpened: (_) {}, child: const Text('app'))),
      ));
      await tester.pumpAndSettle();
      expect(t.service.started, isFalse, reason: 'nobody signed in');
    });

    testWidgets('signed in from the start: push starts', (tester) async {
      final t = await setUp();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pushRepositoryProvider.overrideWithValue(t.repo),
          pushServiceProvider.overrideWithValue(t.service),
          sessionProfileProvider.overrideWith((ref) async => me(AppRole.farmer)),
        ],
        child: MaterialApp(home: PushRegistrar(onOpened: (_) {}, child: const Text('app'))),
      ));
      await tester.pumpAndSettle();
      expect(t.service.started, isTrue);
      expect(t.service.onOpened, isNotNull);
    });
  });

  group('a tapped notification leads to what it is about', () {
    Future<List<String>> tap(WidgetTester tester, AppRole role, NotificationType type, String? refId) async {
      final seen = <String>[];
      late GoRouter router;
      late WidgetRef captured;
      router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => Consumer(builder: (context, ref, _) { captured = ref; return const Text('home'); })),
        GoRoute(path: RoutePaths.operatorOrderDetailPattern, builder: (context, s) { seen.add('operator order ${s.pathParameters['orderId']}'); return const Text('x'); }),
        GoRoute(path: '${RoutePaths.farmerOrders}/:orderId', builder: (context, s) { seen.add('farmer order ${s.pathParameters['orderId']}'); return const Text('x'); }),
        GoRoute(path: RoutePaths.operatorDeliveries, builder: (context, _) { seen.add('deliveries board'); return const Text('x'); }),
        GoRoute(path: RoutePaths.operatorInventory, builder: (context, _) { seen.add('inventory'); return const Text('x'); }),
        GoRoute(path: RoutePaths.farmerDeliver, builder: (context, _) { seen.add('delivery hub'); return const Text('x'); }),
        GoRoute(path: RoutePaths.farmerMarketplaceProductPattern, builder: (context, s) { seen.add('product ${s.pathParameters['productId']}'); return const Text('x'); }),
      ]);
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [sessionProfileProvider.overrideWith((ref) async => me(role))],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      await captured.read(sessionProfileProvider.future);
      await openNotificationTarget(router, captured.read, type, refId);
      await tester.pumpAndSettle();
      return seen;
    }

    testWidgets('an order goes to the order page for a farmer, and the preparation page for an operator', (tester) async {
      expect(await tap(tester, AppRole.farmer, NotificationType.order, 'order-7'), ['farmer order order-7']);
      expect(await tap(tester, AppRole.operator, NotificationType.order, 'order-7'), ['operator order order-7']);
    });

    testWidgets('a low-stock alert goes to the inventory, a back-in-stock notice to the product', (tester) async {
      expect(await tap(tester, AppRole.operator, NotificationType.stock, 'p-1'), ['inventory']);
      expect(await tap(tester, AppRole.farmer, NotificationType.stock, 'p-1'), ['product p-1']);
    });

    testWidgets('a delivery notice for an operator opens the board, and for a partner the delivery hub', (tester) async {
      expect(await tap(tester, AppRole.operator, NotificationType.delivery, 'job-3'), ['deliveries board']);
    });

    testWidgets('with nothing to point at, nothing happens', (tester) async {
      expect(await tap(tester, AppRole.farmer, NotificationType.order, null), isEmpty);
      expect(await tap(tester, AppRole.farmer, NotificationType.other, 'x'), isEmpty);
    });
  });

  group('the notification list', () {
    Future<void> pump(WidgetTester tester, List<AppNotification> items, {AppRole role = AppRole.farmer}) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => const Scaffold(body: NotificationsScreen())),
        GoRoute(path: RoutePaths.farmerNotificationSettings, builder: (context, _) => const Text('farmer settings')),
        GoRoute(path: RoutePaths.operatorNotificationSettings, builder: (context, _) => const Text('operator settings')),
        GoRoute(path: RoutePaths.adminNotificationSettings, builder: (context, _) => const Text('admin settings')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(FakeNotificationsRepository(items)),
          sessionProfileProvider.overrideWith((ref) async => me(role)),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    final items = [
      note('1', NotificationType.order, 'orders'),
      note('2', NotificationType.order, 'payments'),
      note('3', NotificationType.delivery, 'deliveries', read: true),
      note('4', NotificationType.order, 'payments'),
    ];

    testWidgets('chips show each category with its unread count, and choosing one narrows the list', (tester) async {
      await pump(tester, items);
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Orders (1)'), findsOneWidget);
      expect(find.text('Payments (2)'), findsOneWidget);
      expect(find.text('Deliveries'), findsOneWidget, reason: 'nothing unread there');
      expect(find.text('Title 1'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('filter-payments')));
      await tester.tap(find.byKey(const Key('filter-payments')));
      await tester.pumpAndSettle();
      expect(find.text('Title 2'), findsOneWidget);
      expect(find.text('Title 4'), findsOneWidget);
      expect(find.text('Title 1'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('filter-all')));
      await tester.tap(find.byKey(const Key('filter-all')));
      await tester.pumpAndSettle();
      expect(find.text('Title 1'), findsOneWidget);
    });

    testWidgets('a single category needs no chips', (tester) async {
      await pump(tester, [note('1', NotificationType.order, 'orders')]);
      expect(find.byKey(const Key('filter-all')), findsNothing);
    });

    testWidgets('the settings shortcut leads to the right settings for each role', (tester) async {
      await pump(tester, items);
      await tester.tap(find.byKey(const Key('notification-settings')));
      await tester.pumpAndSettle();
      expect(find.text('farmer settings'), findsOneWidget);
    });

    testWidgets('an operator and an admin get their own settings pages', (tester) async {
      await pump(tester, items, role: AppRole.operator);
      await tester.tap(find.byKey(const Key('notification-settings')));
      await tester.pumpAndSettle();
      expect(find.text('operator settings'), findsOneWidget);
    });
  });
}
