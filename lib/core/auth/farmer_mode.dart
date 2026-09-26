import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A village center operator also farms. With this on, the same login uses the farmer screens (their own farm, orders,
/// vehicles, deliveries), kept apart from the center's stock and money; off is the center dashboard. It is a view only:
/// the server still checks the role on every call, and an operator can never check their own vehicles or products.
class FarmerModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

final farmerModeProvider = NotifierProvider<FarmerModeController, bool>(FarmerModeController.new);
