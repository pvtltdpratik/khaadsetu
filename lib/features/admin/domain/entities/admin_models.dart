import 'package:equatable/equatable.dart';

/// People counts for one role, split by segment. `unassigned` only applies to
/// operators (signed up but no center yet) and is 0 for farmers.
class PeopleGroup extends Equatable {
  const PeopleGroup({required this.active, required this.suspended, required this.unassigned, required this.total});

  factory PeopleGroup.fromJson(Map<String, dynamic> json) => PeopleGroup(
        active: (json['active'] as num).toInt(),
        suspended: (json['suspended'] as num).toInt(),
        unassigned: ((json['unassigned'] as num?) ?? 0).toInt(),
        total: (json['total'] as num).toInt(),
      );

  final int active;
  final int suspended;
  final int unassigned;
  final int total;

  @override
  List<Object?> get props => [active, suspended, unassigned, total];
}

class AdminOverview extends Equatable {
  const AdminOverview({
    required this.operators,
    required this.farmers,
    required this.centersActive,
    required this.centersSuspended,
    required this.centersWithoutOperator,
    required this.ordersPending,
    required this.ordersReadyForPickup,
    required this.ordersToday,
    required this.restockPending,
    required this.lowStockItems,
    this.lowStockUnattended = 0,
    this.discrepanciesOpen = 0,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final people = json['people'] as Map<String, dynamic>;
    final centers = json['centers'] as Map<String, dynamic>;
    final orders = json['orders'] as Map<String, dynamic>;
    return AdminOverview(
      operators: PeopleGroup.fromJson(people['operators'] as Map<String, dynamic>),
      farmers: PeopleGroup.fromJson(people['farmers'] as Map<String, dynamic>),
      centersActive: (centers['active'] as num).toInt(),
      centersSuspended: (centers['suspended'] as num).toInt(),
      centersWithoutOperator: (centers['withoutOperator'] as num).toInt(),
      ordersPending: (orders['pending'] as num).toInt(),
      ordersReadyForPickup: (orders['readyForPickup'] as num).toInt(),
      ordersToday: (orders['today'] as num).toInt(),
      restockPending: ((json['restockRequests'] as Map<String, dynamic>)['pending'] as num).toInt(),
      lowStockItems: (json['lowStockItems'] as num).toInt(),
      lowStockUnattended: ((json['lowStockUnattended'] as num?) ?? 0).toInt(),
      discrepanciesOpen: ((json['discrepanciesOpen'] as num?) ?? 0).toInt(),
    );
  }

  final PeopleGroup operators;
  final PeopleGroup farmers;
  final int centersActive;
  final int centersSuspended;
  final int centersWithoutOperator;
  final int ordersPending;
  final int ordersReadyForPickup;
  final int ordersToday;
  final int restockPending;
  final int lowStockItems;

  /// Still low a full day after the operator was alerted: nobody has acted.
  final int lowStockUnattended;

  /// Delivery reports from operators the supply team has not reviewed.
  final int discrepanciesOpen;

  @override
  List<Object?> get props => [
        operators, farmers, centersActive, centersSuspended, centersWithoutOperator,
        ordersPending, ordersReadyForPickup, ordersToday, restockPending, lowStockItems, lowStockUnattended, discrepanciesOpen,
      ];
}

/// The person's role and standing, as the admin categorises them.
enum PersonRole { operator, farmer }

enum PersonSegment { active, suspended, unassigned }

class AdminUser extends Equatable {
  const AdminUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.status,
    required this.role,
    required this.segment,
    required this.ordersCount,
    this.centerId,
    this.centerName,
    this.centerStatus,
    this.village,
    this.landHoldingHectares,
    this.createdAt,
    this.lastSeenAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        userId: json['userId'] as String,
        email: (json['email'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        status: json['status'] as String,
        role: PersonRole.values.byName(json['role'] as String),
        segment: PersonSegment.values.byName(json['segment'] as String),
        ordersCount: ((json['ordersCount'] as num?) ?? 0).toInt(),
        centerId: json['centerId'] as String?,
        centerName: json['centerName'] as String?,
        centerStatus: json['centerStatus'] as String?,
        village: json['village'] as String?,
        landHoldingHectares: (json['landHoldingHectares'] as num?)?.toDouble(),
        createdAt: _date(json['createdAt']),
        lastSeenAt: _date(json['lastSeenAt']),
      );

  final String userId;
  final String email;
  final String name;

  /// The account's status: 'active' or 'suspended'.
  final String status;
  final PersonRole role;
  final PersonSegment segment;
  final int ordersCount;
  final String? centerId;
  final String? centerName;
  final String? centerStatus;
  final String? village;
  final double? landHoldingHectares;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  bool get isSuspended => status == 'suspended';

  /// A name to show: the person's name, else their email, else their id.
  String get displayName => name.isNotEmpty ? name : (email.isNotEmpty ? email : userId);

  @override
  List<Object?> get props => [
        userId, email, name, status, role, segment, ordersCount, centerId, centerName, centerStatus,
        village, landHoldingHectares, createdAt, lastSeenAt,
      ];
}

class AdminUserDetail extends Equatable {
  const AdminUserDetail({required this.user, required this.scans, required this.ordersByStatus, this.homeCenterId});

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] as Map<String, dynamic>;
    final orders = (activity['orders'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    return AdminUserDetail(
      user: AdminUser.fromJson(json),
      scans: (activity['scans'] as num).toInt(),
      ordersByStatus: orders,
      homeCenterId: (json['profile'] as Map<String, dynamic>)['homeCenterId'] as String?,
    );
  }

  final AdminUser user;
  final int scans;
  final Map<String, int> ordersByStatus;
  final String? homeCenterId;

  @override
  List<Object?> get props => [user, scans, ordersByStatus, homeCenterId];
}

class AdminCenter extends Equatable {
  const AdminCenter({
    required this.centerId,
    required this.name,
    required this.village,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.operatorName,
    required this.phone,
    required this.isOpen,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    required this.productsStocked,
    required this.lowStockCount,
    required this.pendingOrders,
    this.operatorId,
    this.operatorEmail,
    this.operatorUserName,
    this.operatorStatus,
  });

  factory AdminCenter.fromJson(Map<String, dynamic> json) => AdminCenter(
        centerId: json['centerId'] as String,
        name: json['name'] as String,
        village: json['village'] as String,
        district: (json['district'] as String?) ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        operatorName: (json['operatorName'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        isOpen: json['isOpen'] as bool,
        opensAt: json['opensAt'] as String,
        closesAt: json['closesAt'] as String,
        status: json['status'] as String,
        productsStocked: ((json['productsStocked'] as num?) ?? 0).toInt(),
        lowStockCount: ((json['lowStockCount'] as num?) ?? 0).toInt(),
        pendingOrders: ((json['pendingOrders'] as num?) ?? 0).toInt(),
        operatorId: json['operatorId'] as String?,
        operatorEmail: json['operatorEmail'] as String?,
        operatorUserName: json['operatorUserName'] as String?,
        operatorStatus: json['operatorStatus'] as String?,
      );

  final String centerId;
  final String name;
  final String village;
  final String district;
  final double latitude;
  final double longitude;
  final String operatorName;
  final String phone;
  final bool isOpen;
  final String opensAt;
  final String closesAt;
  final String status;
  final int productsStocked;
  final int lowStockCount;
  final int pendingOrders;
  final String? operatorId;
  final String? operatorEmail;
  final String? operatorUserName;
  final String? operatorStatus;

  bool get isSuspended => status == 'suspended';
  bool get hasOperator => operatorId != null;

  /// "Shirur, Pune" (or just the village when there is no district).
  String get place => district.isEmpty ? village : '$village, $district';

  /// The operator's name for display, falling back to their email.
  String? get operatorLabel {
    if (!hasOperator) return null;
    final label = (operatorUserName?.isNotEmpty ?? false) ? operatorUserName! : (operatorEmail ?? operatorId!);
    return label;
  }

  @override
  List<Object?> get props => [
        centerId, name, village, district, latitude, longitude, operatorName, phone, isOpen, opensAt, closesAt,
        status, productsStocked, lowStockCount, pendingOrders, operatorId, operatorEmail, operatorUserName, operatorStatus,
      ];
}

/// One product on a center's shelf, as the admin sees it.
class StockItem extends Equatable {
  const StockItem({
    required this.name,
    required this.unit,
    required this.onHand,
    required this.reserved,
    required this.available,
    required this.reorderLevel,
    required this.incoming,
    required this.isLow,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        name: json['name'] as String,
        unit: json['unit'] as String,
        onHand: (json['currentStock'] as num).toInt(),
        reserved: (json['reserved'] as num).toInt(),
        available: (json['available'] as num).toInt(),
        reorderLevel: (json['lowStockThreshold'] as num).toInt(),
        incoming: (json['incoming'] as num).toInt(),
        isLow: json['isLowStock'] as bool,
      );

  final String name;
  final String unit;
  final int onHand;
  final int reserved;
  final int available;
  final int reorderLevel;
  final int incoming;
  final bool isLow;

  @override
  List<Object?> get props => [name, unit, onHand, reserved, available, reorderLevel, incoming, isLow];
}

/// One entry in the audit log.
class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.createdAt,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id'] as String,
        adminEmail: (json['adminEmail'] as String?) ?? '',
        action: json['action'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        details: (json['details'] as Map<String, dynamic>?) ?? const {},
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final String id;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  /// A short sentence for the activity list.
  String get summary => switch (action) {
        'user.suspend' => 'Suspended a ${details['role'] ?? 'user'}',
        'user.reactivate' => 'Reactivated a ${details['role'] ?? 'user'}',
        'center.create' => 'Created center ${details['name'] ?? ''}'.trim(),
        'center.update' => 'Updated a center',
        'center.suspend' => 'Suspended a center',
        'center.reactivate' => 'Reactivated a center',
        'center.assignOperator' => 'Assigned an operator to a center',
        'center.unassignOperator' => 'Removed a center\'s operator',
        'restock.approved' => 'Approved a restock request',
        'restock.fulfilled' => 'Marked a restock delivered',
        _ => action,
      };

  @override
  List<Object?> get props => [id, adminEmail, action, targetType, targetId, details, createdAt];
}

/// The steps a restock request moves through, in order.
enum RestockStatus {
  pending,
  approved,
  fulfilled;

  static RestockStatus parse(String? raw) => values.firstWhere((s) => s.name == raw, orElse: () => pending);

  /// The step an admin can move it to, or null when it is finished.
  RestockStatus? get next => switch (this) {
        pending => approved,
        approved => fulfilled,
        fulfilled => null,
      };
}

/// A center's request for more stock, as the supply team sees it.
class RestockRequest extends Equatable {
  const RestockRequest({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.productName,
    required this.quantity,
    required this.status,
    this.requestedDate,
  });

  factory RestockRequest.fromJson(Map<String, dynamic> json) => RestockRequest(
        id: json['id'] as String,
        centerId: json['centerId'] as String,
        centerName: (json['centerName'] as String?) ?? '',
        productName: (json['productName'] as String?) ?? '',
        quantity: (json['requestedQuantity'] as num).toInt(),
        status: RestockStatus.parse(json['status'] as String?),
        requestedDate: _date(json['requestedDate']),
      );

  final String id;
  final String centerId;
  final String centerName;
  final String productName;
  final int quantity;
  final RestockStatus status;
  final DateTime? requestedDate;

  @override
  List<Object?> get props => [id, centerId, centerName, productName, quantity, status, requestedDate];
}

/// An operator's report that a delivery did not match what was expected.
class StockDiscrepancy extends Equatable {
  const StockDiscrepancy({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.productName,
    required this.expected,
    required this.received,
    required this.note,
    required this.resolved,
    required this.resolutionNote,
    this.createdAt,
  });

  factory StockDiscrepancy.fromJson(Map<String, dynamic> json) => StockDiscrepancy(
        id: json['id'] as String,
        centerId: json['centerId'] as String,
        centerName: (json['centerName'] as String?) ?? '',
        productName: (json['productName'] as String?) ?? '',
        expected: (json['expectedQuantity'] as num).toInt(),
        received: (json['receivedQuantity'] as num).toInt(),
        note: (json['note'] as String?) ?? '',
        resolved: json['status'] == 'resolved',
        resolutionNote: (json['resolutionNote'] as String?) ?? '',
        createdAt: _date(json['createdAt']),
      );

  final String id;
  final String centerId;
  final String centerName;
  final String productName;
  final int expected;
  final int received;
  final String note;
  final bool resolved;
  final String resolutionNote;
  final DateTime? createdAt;

  /// Positive when fewer units arrived than expected.
  int get shortfall => expected - received;

  @override
  List<Object?> get props => [id, centerId, centerName, productName, expected, received, note, resolved, resolutionNote, createdAt];
}

/// A place from the built-in village list, used to fill a new center's coordinates.
class VillageOption extends Equatable {
  const VillageOption({required this.name, required this.district, required this.latitude, required this.longitude});

  factory VillageOption.fromJson(Map<String, dynamic> json) => VillageOption(
        name: json['name'] as String,
        district: json['district'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  final String name;
  final String district;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [name, district, latitude, longitude];
}

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
