import 'dart:typed_data';

import 'resale_models.dart';

/// Everything about farmers reselling leftover fertilizer: the farmer's side, the village
/// center's, and the admin's. One interface so screens can be tested with a fake.
abstract class ResaleRepository {
  // ---- the farmer ----
  Future<List<EligibleProduct>> eligible();
  Future<PriceGuide> suggest({required String productId, required ResaleCondition condition, String? mfgDate});

  /// Creates the listing, uploads both photos and sends it to the center. Returns the listing.
  Future<ResaleListing> create(NewListing listing, {required Uint8List front, required Uint8List back});
  Future<List<ResaleListing>> mine();
  Future<ResaleListing> listing(String id);
  Future<ResaleListing> withdraw(String id);
  Future<WalletState> wallet();

  /// A buyer's complaint about goods collected in the last 48 hours.
  Future<void> raiseDispute({required String orderId, required String reason});

  // ---- the village center ----
  Future<List<ResaleListing>> queue({List<ResaleStatus>? statuses});
  Future<Uint8List> photo(String id, String kind);
  Future<ResaleListing> preapprove(String id);
  Future<ResaleListing> requestInspection(String id, {String note = ''});
  Future<ResaleListing> reject(String id, String reason);
  Future<ResaleListing> inspect(String id, InspectionChecklist checklist);
  Future<PriceGuide> suggestAtCounter({required String productId, required ResaleCondition condition, String? visual, String? mfgDate});
  Future<List<SellerMatch>> findSellers(String query);
  Future<ResaleListing> walkIn({String? sellerId, String? sellerName, String? sellerPhone, required String productId, required PayoutMode payoutMode, required InspectionChecklist checklist});
  Future<List<PayoutDue>> cashDue();
  Future<void> markCashPaid(String saleId);

  // ---- the platform ----
  Future<List<ResaleDispute>> disputes({String? status});
  Future<void> resolveDispute(String id, {required bool uphold, int? refundPercent, String note = ''});
  Future<List<PayoutDue>> upiPayouts();
  Future<void> markUpiPaid(String saleId, {String reference = ''});
}
