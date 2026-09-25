import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/operator/orders/domain/entities/order.dart';
import 'package:khaadsetu_version1/features/operator/presentation/widgets/operator_insights.dart';

final now = DateTime(2026, 9, 26, 15, 0);

Order order(String id, String who, OrderStatus status, DateTime at, {double price = 100, int qty = 2, OrderType type = OrderType.appOrder}) =>
    Order(id: id, customerName: who, type: type, status: status, items: [OrderLineItem(productName: 'Neem', quantity: qty, unitPrice: price)], createdAt: at, pickupOtp: null);

Future<void> pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: SingleChildScrollView(child: child))));
  await tester.pumpAndSettle();
}

void main() {
  test('weekly sales count only completed orders, one entry per day, ending today', () {
    final week = weeklySales([
      order('a', 'Ramesh', OrderStatus.completed, DateTime(2026, 9, 26, 9)),
      order('b', 'Sunita', OrderStatus.completed, DateTime(2026, 9, 26, 11), price: 50),
      order('c', 'Anil', OrderStatus.pending, DateTime(2026, 9, 26, 12)),
      order('d', 'Old', OrderStatus.completed, DateTime(2026, 9, 20)),
      order('e', 'Too old', OrderStatus.completed, DateTime(2026, 9, 1)),
    ], now);
    expect(week, hasLength(7));
    expect(week.last.day, DateTime(2026, 9, 26));
    expect(week.last.sales, 300);
    expect(week.first.day, DateTime(2026, 9, 20));
    expect(week.first.sales, 200);
    expect(week.fold<double>(0, (s, d) => s + d.sales), 500);
  });

  test('times read as minutes, hours, then days', () {
    expect(ago(now, now), 'just now');
    expect(ago(now.subtract(const Duration(minutes: 5)), now), '5 min ago');
    expect(ago(now.subtract(const Duration(hours: 3)), now), '3 h ago');
    expect(ago(now.subtract(const Duration(days: 1)), now), '1 day ago');
    expect(ago(now.subtract(const Duration(days: 4)), now), '4 days ago');
  });

  testWidgets('the chart shows the week total and seven bars', (tester) async {
    await pump(tester, WeeklySalesChart(now: now, orders: [order('a', 'Ramesh', OrderStatus.completed, DateTime(2026, 9, 26, 9))]));
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.byKey(const Key('weekly-total')), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('bar-$i')), findsOneWidget);
    }
    expect(tester.getSize(find.byKey(const Key('bar-6'))).height, greaterThan(tester.getSize(find.byKey(const Key('bar-0'))).height));
  });

  testWidgets('the feed lists the newest five first with what happened', (tester) async {
    final orders = [
      order('1', 'Ramesh', OrderStatus.pending, now.subtract(const Duration(minutes: 5))),
      order('2', 'Sunita', OrderStatus.completed, now.subtract(const Duration(hours: 2)), type: OrderType.walkIn),
      order('3', 'Anil', OrderStatus.readyForPickup, now.subtract(const Duration(hours: 5))),
      order('4', 'Meena', OrderStatus.cancelled, now.subtract(const Duration(days: 1))),
      order('5', 'Kiran', OrderStatus.completed, now.subtract(const Duration(days: 2))),
      order('6', 'Extra', OrderStatus.pending, now.subtract(const Duration(days: 3))),
    ];
    await pump(tester, RecentActivity(orders: orders, now: now));
    expect(find.text('Ramesh placed an order'), findsOneWidget);
    expect(find.text('Sunita bought at the counter'), findsOneWidget);
    expect(find.text('Anil has an order ready for pickup'), findsOneWidget);
    expect(find.text('Meena cancelled an order'), findsOneWidget);
    expect(find.text('Kiran collected an order'), findsOneWidget);
    expect(find.textContaining('Extra'), findsNothing, reason: 'only the latest five');
    expect(find.text('5 min ago'), findsOneWidget);
  });

  testWidgets('an empty feed says so', (tester) async {
    await pump(tester, RecentActivity(orders: const [], now: now));
    expect(find.text('Nothing yet today'), findsOneWidget);
  });
}
