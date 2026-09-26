import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../../core/auth/session_profile.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../delivery/presentation/providers/delivery_providers.dart';
import '../domain/entities/app_notification.dart';

/// How a provider is read: `ref.read` from a widget or from a provider works for this.
typedef ReadProvider = T Function<T>(ProviderListenable<T> provider);

/// Takes the user to what a notification is about. Used when a notification in the list is tapped, and when a push
/// notification is tapped with the app open, in the background, or closed.
Future<void> openNotificationTarget(GoRouter router, ReadProvider read, NotificationType type, String? refId) async {
  if (refId == null || refId.isEmpty) return;
  bool isOperator() => read(sessionProfileProvider).value?.role == AppRole.operator;

  switch (type) {
    case NotificationType.scan:
      router.go(RoutePaths.farmerSoilScanResult(refId));
    case NotificationType.scheme:
      router.go(RoutePaths.farmerCommunityScheme(refId));
    case NotificationType.order:
      // An operator opens the order to prepare it; a farmer sees their pickup code.
      router.push(isOperator() ? RoutePaths.operatorOrderDetail(refId) : RoutePaths.farmerOrder(refId));
    case NotificationType.stock:
      // An operator's low-stock alert goes to the inventory; a farmer's "back in stock" goes to the product.
      if (isOperator()) {
        router.go(RoutePaths.operatorInventory);
      } else {
        router.push(RoutePaths.farmerMarketplaceProduct(refId));
      }
    case NotificationType.restock:
      if (isOperator()) router.go(RoutePaths.operatorInventory);
    case NotificationType.delivery:
      await _openDelivery(router, read, refId, isOperator());
    case NotificationType.account:
    case NotificationType.other:
      break; // the text says it all
  }
}

/// A delivery notice points at an order (to the buyer, or the center), or at a job: a load I sent, or a job I am
/// doing as the partner. Which of those a job id is depends on who is asking, so the server is asked whether it is
/// my load.
Future<void> _openDelivery(GoRouter router, ReadProvider read, String refId, bool operator) async {
  if (refId.startsWith('order-')) {
    router.push(operator ? RoutePaths.operatorOrderDetail(refId) : RoutePaths.farmerOrder(refId));
    return;
  }
  // An application to check, a delivery with no driver, cash handed over: the board has it all.
  if (operator) {
    router.push(RoutePaths.operatorDeliveries);
    return;
  }
  if (refId.startsWith('job-')) {
    try {
      await read(deliveryRepositoryProvider).load(refId);
      router.push(RoutePaths.farmerLoad(refId));
      return;
    } catch (_) {
      // Not my load, so it is a job for me as the partner.
    }
  }
  router.push(RoutePaths.farmerDeliver);
}
