import 'dart:typed_data';

import '../../domain/entities/delivery_models.dart';
import 'management_models.dart';

/// What the operator (their own center) and the admin (every center) can see and
/// do about home delivery. The operator-only calls throw for the admin.
abstract class DeliveryManagementRepository {
  /// Deliveries, active ones first. [status] narrows to one state.
  Future<List<ManagedDelivery>> deliveries({DeliveryStatus? status});

  /// One delivery, with the buyer's phone and email, the drop address, and (for the admin) which center it belongs to.
  Future<ManagedDelivery> deliveryDetail(String id);

  /// Every vehicle a delivery partner has sent for checking — an operator only sees this for a partner reviewed at
  /// their own center; the admin sees it for anyone.
  Future<List<PartnerVehicle>> vehiclesOf(String ownerId);

  /// Applications to deliver, waiting ones first.
  Future<List<PartnerApplication>> partners({PartnerStatus? status, String? query});

  Future<PartnerApplication> partner(String userId);

  /// The licence or RC photo (`kind` is `licence` or `rc`).
  Future<Uint8List> document(String userId, String kind);

  /// Approve, reject, suspend or reactivate. [note] is what the farmer is told.
  Future<PartnerApplication> review(String userId, ReviewAction action, {String? note});

  // ---- the operator's own center only ----

  Future<List<AssignCandidate>> candidates(String jobId);

  Future<ManagedDelivery> assign(String jobId, String partnerId);

  /// Types the code the partner reads out; the goods leave the shelf.
  Future<ManagedDelivery> handover(String jobId, String otp);

  Future<List<CashOwed>> cashOwed();

  /// Records [amount] handed over by a partner; returns what is still owed.
  Future<List<CashOwed>> settleCash(String partnerId, double amount, {String note = ''});
}
