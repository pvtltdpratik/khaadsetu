import 'dart:typed_data';

import '../../../farmer/centers/domain/entities/nearby_center.dart';
import '../entities/delivery_models.dart';

/// Home delivery, from every side a farmer can be on: buying, delivering for
/// others, and sending a load to another farm. One interface so the screens
/// can be tested with a fake.
abstract class DeliveryRepository {
  // ---- buying: what would it cost, and where is it now ----

  /// What bringing [items] to [location] would cost. [centerId] pins the center;
  /// without it the nearest working one is used.
  Future<DeliveryQuote> quote({required List<CartLine> items, required FarmerLocation location, String? centerId});

  Future<DeliveryTracking> tracking(String orderId);

  /// The buyer collects it themselves after all (until it is on the road).
  Future<void> switchToPickup(String orderId);

  Future<void> rateDelivery({required String orderId, required int stars, String comment = ''});

  // ---- being a delivery partner ----

  Future<PartnerProfile> partner();

  /// Saves only the fields that are given (see the server's `PUT /delivery/partner`).
  Future<PartnerProfile> savePartner(Map<String, dynamic> changes);

  /// Uploads the licence or the RC (`kind` is `licence` or `rc`).
  Future<PartnerProfile> uploadDocument({required String kind, required Uint8List bytes, required String filename});

  Future<PartnerProfile> submitApplication();

  Future<PartnerProfile> setOnline(bool online);

  /// Stops delivering and removes the papers.
  Future<void> withdraw();

  /// Tells the server where the partner is (nearest-first matching, and the buyer's map).
  Future<void> shareLocation({required double latitude, required double longitude});

  Future<List<PartnerJob>> offers();

  Future<List<PartnerJob>> activeJobs();

  Future<PartnerJob> accept(String jobId);

  Future<void> decline(String jobId);

  /// Enters the buyer's (or receiver's) drop code. Wrong codes throw an [ApiException] saying how many tries are left.
  Future<PartnerJob> deliver({required String jobId, required String otp});

  Future<void> rateBuyer({required String jobId, required int stars, String comment = ''});

  Future<Wallet> wallet();

  // ---- trips ----

  Future<List<Trip>> myTrips();

  Future<Trip> postTrip({required GeoPoint from, required GeoPoint to, required DateTime date, required int spareKg, String note = ''});

  Future<void> cancelTrip(String id);

  /// Trips other farmers posted that start near [location] and have room for [weightKg].
  Future<List<Trip>> tripBoard({required FarmerLocation location, double weightKg = 0});

  // ---- carrying a load for another farmer ----

  Future<LoadQuote> loadQuote(LoadRequest request);

  Future<DeliveryTracking> sendLoad(LoadRequest request);

  Future<List<DeliveryTracking>> myLoads();

  Future<DeliveryTracking> load(String jobId);

  Future<DeliveryTracking> cancelLoad(String jobId);

  /// The sender types the partner's handover code when giving the load.
  Future<DeliveryTracking> handOverLoad({required String jobId, required String otp});

  Future<void> rateLoad({required String jobId, required int stars, String comment = ''});
}
