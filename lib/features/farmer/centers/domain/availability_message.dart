import 'entities/nearby_center.dart';

enum AvailabilityKind {
  /// The nearest center has it, and is open.
  readyForPickup,

  /// The nearest center has it but is closed right now (reserve, collect later).
  closedNow,

  /// The nearest center lacks it, another one has it.
  elsewhere,

  /// Some stock exists nearby, but no single center has enough.
  partial,

  /// Nothing, anywhere in range.
  outOfStock,

  /// There are no centers in range at all.
  noCenters,
}

/// What to tell a farmer about one product they want [quantity] of.
class AvailabilityMessage {
  const AvailabilityMessage({required this.kind, required this.text, this.centerId});

  final AvailabilityKind kind;
  final String text;

  /// The center that can fill the whole order, if any: what to reserve at.
  final String? centerId;

  bool get canReserve => centerId != null;
}

String _km(double km) => '${km.toStringAsFixed(1)} km';

/// Turns a nearby-centers answer for a ONE-product cart into the sentence the
/// product page shows. Pure, so every case is unit-tested.
///
/// Cases, in order:
///  1. the nearest center has all of it and is open      -> ready for pickup
///  2. the nearest has all of it but is closed           -> reserve and collect later
///  3. the nearest lacks it but another has all of it    -> point to that one
///  4. no center has enough, but some have some          -> say how many, suggest fewer
///  5. none has any                                      -> out of stock
AvailabilityMessage describeAvailability(NearbyResult result, {required int quantity}) {
  final centers = result.centers;
  if (centers.isEmpty) {
    return const AvailabilityMessage(kind: AvailabilityKind.noCenters, text: 'There are no village centers near you yet.');
  }

  int have(NearbyCenter c) => c.inventory.items.isEmpty ? 0 : c.inventory.items.first.available;
  bool complete(NearbyCenter c) => c.inventory.status == InventoryStatus.all;

  final nearest = centers.reduce((a, b) => a.distanceKm <= b.distanceKm ? a : b);

  if (complete(nearest)) {
    final where = nearest.center.name;
    if (nearest.hours.isOpenNow) {
      return AvailabilityMessage(
        kind: AvailabilityKind.readyForPickup,
        text: 'Available at $where, ${_km(nearest.distanceKm)} away. Ready for pickup.',
        centerId: nearest.center.centerId,
      );
    }
    return AvailabilityMessage(
      kind: AvailabilityKind.closedNow,
      text: 'Available at $where. ${nearest.hours.label}. Reserve it now and collect it when they open.',
      centerId: nearest.center.centerId,
    );
  }

  // The nearest-to-farthest centers that could fill the whole order.
  final full = centers.where(complete).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  if (full.isNotEmpty) {
    final other = full.first;
    final note = other.hours.isOpenNow ? '' : ' (${other.hours.label.toLowerCase()})';
    return AvailabilityMessage(
      kind: AvailabilityKind.elsewhere,
      text: 'Not available at your nearest center. Available at ${other.center.name}, ${_km(other.distanceKm)} away$note.',
      centerId: other.center.centerId,
    );
  }

  final withSome = centers.where((c) => have(c) > 0).toList()..sort((a, b) => have(b).compareTo(have(a)));
  if (withSome.isNotEmpty) {
    final best = withSome.first;
    final n = have(best);
    return AvailabilityMessage(
      kind: AvailabilityKind.partial,
      text: 'Only $n available at ${best.center.name}, ${_km(best.distanceKm)} away; you need $quantity. '
          'No nearby center has enough right now. Try ${n == 1 ? 'ordering 1' : 'a smaller quantity'}.',
    );
  }

  return const AvailabilityMessage(
    kind: AvailabilityKind.outOfStock,
    text: 'Currently out of stock at centers near you.',
  );
}
