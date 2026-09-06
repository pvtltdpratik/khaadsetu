// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OrdersTableTable extends OrdersTable
    with TableInfo<$OrdersTableTable, OrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pickupOtpMeta = const VerificationMeta(
    'pickupOtp',
  );
  @override
  late final GeneratedColumn<String> pickupOtp = GeneratedColumn<String>(
    'pickup_otp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerName,
    type,
    status,
    itemsJson,
    createdAt,
    pickupOtp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('pickup_otp')) {
      context.handle(
        _pickupOtpMeta,
        pickupOtp.isAcceptableOrUnknown(data['pickup_otp']!, _pickupOtpMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      pickupOtp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pickup_otp'],
      ),
    );
  }

  @override
  $OrdersTableTable createAlias(String alias) {
    return $OrdersTableTable(attachedDatabase, alias);
  }
}

class OrderRow extends DataClass implements Insertable<OrderRow> {
  final String id;
  final String customerName;
  final String type;
  final String status;
  final String itemsJson;
  final DateTime createdAt;
  final String? pickupOtp;
  const OrderRow({
    required this.id,
    required this.customerName,
    required this.type,
    required this.status,
    required this.itemsJson,
    required this.createdAt,
    this.pickupOtp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_name'] = Variable<String>(customerName);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    map['items_json'] = Variable<String>(itemsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || pickupOtp != null) {
      map['pickup_otp'] = Variable<String>(pickupOtp);
    }
    return map;
  }

  OrdersTableCompanion toCompanion(bool nullToAbsent) {
    return OrdersTableCompanion(
      id: Value(id),
      customerName: Value(customerName),
      type: Value(type),
      status: Value(status),
      itemsJson: Value(itemsJson),
      createdAt: Value(createdAt),
      pickupOtp: pickupOtp == null && nullToAbsent
          ? const Value.absent()
          : Value(pickupOtp),
    );
  }

  factory OrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderRow(
      id: serializer.fromJson<String>(json['id']),
      customerName: serializer.fromJson<String>(json['customerName']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      pickupOtp: serializer.fromJson<String?>(json['pickupOtp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerName': serializer.toJson<String>(customerName),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'pickupOtp': serializer.toJson<String?>(pickupOtp),
    };
  }

  OrderRow copyWith({
    String? id,
    String? customerName,
    String? type,
    String? status,
    String? itemsJson,
    DateTime? createdAt,
    Value<String?> pickupOtp = const Value.absent(),
  }) => OrderRow(
    id: id ?? this.id,
    customerName: customerName ?? this.customerName,
    type: type ?? this.type,
    status: status ?? this.status,
    itemsJson: itemsJson ?? this.itemsJson,
    createdAt: createdAt ?? this.createdAt,
    pickupOtp: pickupOtp.present ? pickupOtp.value : this.pickupOtp,
  );
  OrderRow copyWithCompanion(OrdersTableCompanion data) {
    return OrderRow(
      id: data.id.present ? data.id.value : this.id,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pickupOtp: data.pickupOtp.present ? data.pickupOtp.value : this.pickupOtp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderRow(')
          ..write('id: $id, ')
          ..write('customerName: $customerName, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('pickupOtp: $pickupOtp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerName,
    type,
    status,
    itemsJson,
    createdAt,
    pickupOtp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRow &&
          other.id == this.id &&
          other.customerName == this.customerName &&
          other.type == this.type &&
          other.status == this.status &&
          other.itemsJson == this.itemsJson &&
          other.createdAt == this.createdAt &&
          other.pickupOtp == this.pickupOtp);
}

class OrdersTableCompanion extends UpdateCompanion<OrderRow> {
  final Value<String> id;
  final Value<String> customerName;
  final Value<String> type;
  final Value<String> status;
  final Value<String> itemsJson;
  final Value<DateTime> createdAt;
  final Value<String?> pickupOtp;
  final Value<int> rowid;
  const OrdersTableCompanion({
    this.id = const Value.absent(),
    this.customerName = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pickupOtp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersTableCompanion.insert({
    required String id,
    required String customerName,
    required String type,
    required String status,
    required String itemsJson,
    required DateTime createdAt,
    this.pickupOtp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerName = Value(customerName),
       type = Value(type),
       status = Value(status),
       itemsJson = Value(itemsJson),
       createdAt = Value(createdAt);
  static Insertable<OrderRow> custom({
    Expression<String>? id,
    Expression<String>? customerName,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? itemsJson,
    Expression<DateTime>? createdAt,
    Expression<String>? pickupOtp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerName != null) 'customer_name': customerName,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (itemsJson != null) 'items_json': itemsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (pickupOtp != null) 'pickup_otp': pickupOtp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? customerName,
    Value<String>? type,
    Value<String>? status,
    Value<String>? itemsJson,
    Value<DateTime>? createdAt,
    Value<String?>? pickupOtp,
    Value<int>? rowid,
  }) {
    return OrdersTableCompanion(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      type: type ?? this.type,
      status: status ?? this.status,
      itemsJson: itemsJson ?? this.itemsJson,
      createdAt: createdAt ?? this.createdAt,
      pickupOtp: pickupOtp ?? this.pickupOtp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pickupOtp.present) {
      map['pickup_otp'] = Variable<String>(pickupOtp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableCompanion(')
          ..write('id: $id, ')
          ..write('customerName: $customerName, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('pickupOtp: $pickupOtp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RestockRequestsTableTable extends RestockRequestsTable
    with TableInfo<$RestockRequestsTableTable, RestockRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestockRequestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestedQuantityMeta = const VerificationMeta(
    'requestedQuantity',
  );
  @override
  late final GeneratedColumn<int> requestedQuantity = GeneratedColumn<int>(
    'requested_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestedDateMeta = const VerificationMeta(
    'requestedDate',
  );
  @override
  late final GeneratedColumn<DateTime> requestedDate =
      GeneratedColumn<DateTime>(
        'requested_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    itemName,
    requestedQuantity,
    status,
    requestedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restock_requests_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestockRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('requested_quantity')) {
      context.handle(
        _requestedQuantityMeta,
        requestedQuantity.isAcceptableOrUnknown(
          data['requested_quantity']!,
          _requestedQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedQuantityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('requested_date')) {
      context.handle(
        _requestedDateMeta,
        requestedDate.isAcceptableOrUnknown(
          data['requested_date']!,
          _requestedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RestockRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestockRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      requestedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}requested_quantity'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      requestedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_date'],
      )!,
    );
  }

  @override
  $RestockRequestsTableTable createAlias(String alias) {
    return $RestockRequestsTableTable(attachedDatabase, alias);
  }
}

class RestockRequestRow extends DataClass
    implements Insertable<RestockRequestRow> {
  final String id;
  final String itemId;
  final String itemName;
  final int requestedQuantity;
  final String status;
  final DateTime requestedDate;
  const RestockRequestRow({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.requestedQuantity,
    required this.status,
    required this.requestedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['item_name'] = Variable<String>(itemName);
    map['requested_quantity'] = Variable<int>(requestedQuantity);
    map['status'] = Variable<String>(status);
    map['requested_date'] = Variable<DateTime>(requestedDate);
    return map;
  }

  RestockRequestsTableCompanion toCompanion(bool nullToAbsent) {
    return RestockRequestsTableCompanion(
      id: Value(id),
      itemId: Value(itemId),
      itemName: Value(itemName),
      requestedQuantity: Value(requestedQuantity),
      status: Value(status),
      requestedDate: Value(requestedDate),
    );
  }

  factory RestockRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestockRequestRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      requestedQuantity: serializer.fromJson<int>(json['requestedQuantity']),
      status: serializer.fromJson<String>(json['status']),
      requestedDate: serializer.fromJson<DateTime>(json['requestedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'itemName': serializer.toJson<String>(itemName),
      'requestedQuantity': serializer.toJson<int>(requestedQuantity),
      'status': serializer.toJson<String>(status),
      'requestedDate': serializer.toJson<DateTime>(requestedDate),
    };
  }

  RestockRequestRow copyWith({
    String? id,
    String? itemId,
    String? itemName,
    int? requestedQuantity,
    String? status,
    DateTime? requestedDate,
  }) => RestockRequestRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    itemName: itemName ?? this.itemName,
    requestedQuantity: requestedQuantity ?? this.requestedQuantity,
    status: status ?? this.status,
    requestedDate: requestedDate ?? this.requestedDate,
  );
  RestockRequestRow copyWithCompanion(RestockRequestsTableCompanion data) {
    return RestockRequestRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      requestedQuantity: data.requestedQuantity.present
          ? data.requestedQuantity.value
          : this.requestedQuantity,
      status: data.status.present ? data.status.value : this.status,
      requestedDate: data.requestedDate.present
          ? data.requestedDate.value
          : this.requestedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestockRequestRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemName: $itemName, ')
          ..write('requestedQuantity: $requestedQuantity, ')
          ..write('status: $status, ')
          ..write('requestedDate: $requestedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    itemName,
    requestedQuantity,
    status,
    requestedDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestockRequestRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.itemName == this.itemName &&
          other.requestedQuantity == this.requestedQuantity &&
          other.status == this.status &&
          other.requestedDate == this.requestedDate);
}

class RestockRequestsTableCompanion extends UpdateCompanion<RestockRequestRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> itemName;
  final Value<int> requestedQuantity;
  final Value<String> status;
  final Value<DateTime> requestedDate;
  final Value<int> rowid;
  const RestockRequestsTableCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.requestedQuantity = const Value.absent(),
    this.status = const Value.absent(),
    this.requestedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestockRequestsTableCompanion.insert({
    required String id,
    required String itemId,
    required String itemName,
    required int requestedQuantity,
    required String status,
    required DateTime requestedDate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       itemName = Value(itemName),
       requestedQuantity = Value(requestedQuantity),
       status = Value(status),
       requestedDate = Value(requestedDate);
  static Insertable<RestockRequestRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? itemName,
    Expression<int>? requestedQuantity,
    Expression<String>? status,
    Expression<DateTime>? requestedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (itemName != null) 'item_name': itemName,
      if (requestedQuantity != null) 'requested_quantity': requestedQuantity,
      if (status != null) 'status': status,
      if (requestedDate != null) 'requested_date': requestedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestockRequestsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? itemName,
    Value<int>? requestedQuantity,
    Value<String>? status,
    Value<DateTime>? requestedDate,
    Value<int>? rowid,
  }) {
    return RestockRequestsTableCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      status: status ?? this.status,
      requestedDate: requestedDate ?? this.requestedDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (requestedQuantity.present) {
      map['requested_quantity'] = Variable<int>(requestedQuantity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (requestedDate.present) {
      map['requested_date'] = Variable<DateTime>(requestedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestockRequestsTableCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemName: $itemName, ')
          ..write('requestedQuantity: $requestedQuantity, ')
          ..write('status: $status, ')
          ..write('requestedDate: $requestedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemeApplicationsTableTable extends SchemeApplicationsTable
    with TableInfo<$SchemeApplicationsTableTable, SchemeApplicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemeApplicationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _schemeIdMeta = const VerificationMeta(
    'schemeId',
  );
  @override
  late final GeneratedColumn<String> schemeId = GeneratedColumn<String>(
    'scheme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedDateMeta = const VerificationMeta(
    'appliedDate',
  );
  @override
  late final GeneratedColumn<DateTime> appliedDate = GeneratedColumn<DateTime>(
    'applied_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [schemeId, status, appliedDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheme_applications_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemeApplicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scheme_id')) {
      context.handle(
        _schemeIdMeta,
        schemeId.isAcceptableOrUnknown(data['scheme_id']!, _schemeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_schemeIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('applied_date')) {
      context.handle(
        _appliedDateMeta,
        appliedDate.isAcceptableOrUnknown(
          data['applied_date']!,
          _appliedDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {schemeId};
  @override
  SchemeApplicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemeApplicationRow(
      schemeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheme_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      appliedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_date'],
      ),
    );
  }

  @override
  $SchemeApplicationsTableTable createAlias(String alias) {
    return $SchemeApplicationsTableTable(attachedDatabase, alias);
  }
}

class SchemeApplicationRow extends DataClass
    implements Insertable<SchemeApplicationRow> {
  final String schemeId;
  final String status;
  final DateTime? appliedDate;
  const SchemeApplicationRow({
    required this.schemeId,
    required this.status,
    this.appliedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scheme_id'] = Variable<String>(schemeId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || appliedDate != null) {
      map['applied_date'] = Variable<DateTime>(appliedDate);
    }
    return map;
  }

  SchemeApplicationsTableCompanion toCompanion(bool nullToAbsent) {
    return SchemeApplicationsTableCompanion(
      schemeId: Value(schemeId),
      status: Value(status),
      appliedDate: appliedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedDate),
    );
  }

  factory SchemeApplicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemeApplicationRow(
      schemeId: serializer.fromJson<String>(json['schemeId']),
      status: serializer.fromJson<String>(json['status']),
      appliedDate: serializer.fromJson<DateTime?>(json['appliedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schemeId': serializer.toJson<String>(schemeId),
      'status': serializer.toJson<String>(status),
      'appliedDate': serializer.toJson<DateTime?>(appliedDate),
    };
  }

  SchemeApplicationRow copyWith({
    String? schemeId,
    String? status,
    Value<DateTime?> appliedDate = const Value.absent(),
  }) => SchemeApplicationRow(
    schemeId: schemeId ?? this.schemeId,
    status: status ?? this.status,
    appliedDate: appliedDate.present ? appliedDate.value : this.appliedDate,
  );
  SchemeApplicationRow copyWithCompanion(
    SchemeApplicationsTableCompanion data,
  ) {
    return SchemeApplicationRow(
      schemeId: data.schemeId.present ? data.schemeId.value : this.schemeId,
      status: data.status.present ? data.status.value : this.status,
      appliedDate: data.appliedDate.present
          ? data.appliedDate.value
          : this.appliedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemeApplicationRow(')
          ..write('schemeId: $schemeId, ')
          ..write('status: $status, ')
          ..write('appliedDate: $appliedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(schemeId, status, appliedDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemeApplicationRow &&
          other.schemeId == this.schemeId &&
          other.status == this.status &&
          other.appliedDate == this.appliedDate);
}

class SchemeApplicationsTableCompanion
    extends UpdateCompanion<SchemeApplicationRow> {
  final Value<String> schemeId;
  final Value<String> status;
  final Value<DateTime?> appliedDate;
  final Value<int> rowid;
  const SchemeApplicationsTableCompanion({
    this.schemeId = const Value.absent(),
    this.status = const Value.absent(),
    this.appliedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchemeApplicationsTableCompanion.insert({
    required String schemeId,
    required String status,
    this.appliedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : schemeId = Value(schemeId),
       status = Value(status);
  static Insertable<SchemeApplicationRow> custom({
    Expression<String>? schemeId,
    Expression<String>? status,
    Expression<DateTime>? appliedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (schemeId != null) 'scheme_id': schemeId,
      if (status != null) 'status': status,
      if (appliedDate != null) 'applied_date': appliedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchemeApplicationsTableCompanion copyWith({
    Value<String>? schemeId,
    Value<String>? status,
    Value<DateTime?>? appliedDate,
    Value<int>? rowid,
  }) {
    return SchemeApplicationsTableCompanion(
      schemeId: schemeId ?? this.schemeId,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (schemeId.present) {
      map['scheme_id'] = Variable<String>(schemeId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (appliedDate.present) {
      map['applied_date'] = Variable<DateTime>(appliedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemeApplicationsTableCompanion(')
          ..write('schemeId: $schemeId, ')
          ..write('status: $status, ')
          ..write('appliedDate: $appliedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OrdersTableTable ordersTable = $OrdersTableTable(this);
  late final $RestockRequestsTableTable restockRequestsTable =
      $RestockRequestsTableTable(this);
  late final $SchemeApplicationsTableTable schemeApplicationsTable =
      $SchemeApplicationsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ordersTable,
    restockRequestsTable,
    schemeApplicationsTable,
  ];
}

typedef $$OrdersTableTableCreateCompanionBuilder =
    OrdersTableCompanion Function({
      required String id,
      required String customerName,
      required String type,
      required String status,
      required String itemsJson,
      required DateTime createdAt,
      Value<String?> pickupOtp,
      Value<int> rowid,
    });
typedef $$OrdersTableTableUpdateCompanionBuilder =
    OrdersTableCompanion Function({
      Value<String> id,
      Value<String> customerName,
      Value<String> type,
      Value<String> status,
      Value<String> itemsJson,
      Value<DateTime> createdAt,
      Value<String?> pickupOtp,
      Value<int> rowid,
    });

class $$OrdersTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pickupOtp => $composableBuilder(
    column: $table.pickupOtp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pickupOtp => $composableBuilder(
    column: $table.pickupOtp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get pickupOtp =>
      $composableBuilder(column: $table.pickupOtp, builder: (column) => column);
}

class $$OrdersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTableTable,
          OrderRow,
          $$OrdersTableTableFilterComposer,
          $$OrdersTableTableOrderingComposer,
          $$OrdersTableTableAnnotationComposer,
          $$OrdersTableTableCreateCompanionBuilder,
          $$OrdersTableTableUpdateCompanionBuilder,
          (
            OrderRow,
            BaseReferences<_$AppDatabase, $OrdersTableTable, OrderRow>,
          ),
          OrderRow,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableTableManager(_$AppDatabase db, $OrdersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> pickupOtp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion(
                id: id,
                customerName: customerName,
                type: type,
                status: status,
                itemsJson: itemsJson,
                createdAt: createdAt,
                pickupOtp: pickupOtp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerName,
                required String type,
                required String status,
                required String itemsJson,
                required DateTime createdAt,
                Value<String?> pickupOtp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion.insert(
                id: id,
                customerName: customerName,
                type: type,
                status: status,
                itemsJson: itemsJson,
                createdAt: createdAt,
                pickupOtp: pickupOtp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrdersTableTable, OrderRow>(table),
                  BaseReferences<_$AppDatabase, $OrdersTableTable, OrderRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTableTable,
      OrderRow,
      $$OrdersTableTableFilterComposer,
      $$OrdersTableTableOrderingComposer,
      $$OrdersTableTableAnnotationComposer,
      $$OrdersTableTableCreateCompanionBuilder,
      $$OrdersTableTableUpdateCompanionBuilder,
      (OrderRow, BaseReferences<_$AppDatabase, $OrdersTableTable, OrderRow>),
      OrderRow,
      PrefetchHooks Function()
    >;
typedef $$RestockRequestsTableTableCreateCompanionBuilder =
    RestockRequestsTableCompanion Function({
      required String id,
      required String itemId,
      required String itemName,
      required int requestedQuantity,
      required String status,
      required DateTime requestedDate,
      Value<int> rowid,
    });
typedef $$RestockRequestsTableTableUpdateCompanionBuilder =
    RestockRequestsTableCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> itemName,
      Value<int> requestedQuantity,
      Value<String> status,
      Value<DateTime> requestedDate,
      Value<int> rowid,
    });

class $$RestockRequestsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RestockRequestsTableTable> {
  $$RestockRequestsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestedQuantity => $composableBuilder(
    column: $table.requestedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedDate => $composableBuilder(
    column: $table.requestedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RestockRequestsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RestockRequestsTableTable> {
  $$RestockRequestsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestedQuantity => $composableBuilder(
    column: $table.requestedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedDate => $composableBuilder(
    column: $table.requestedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RestockRequestsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestockRequestsTableTable> {
  $$RestockRequestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<int> get requestedQuantity => $composableBuilder(
    column: $table.requestedQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedDate => $composableBuilder(
    column: $table.requestedDate,
    builder: (column) => column,
  );
}

class $$RestockRequestsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RestockRequestsTableTable,
          RestockRequestRow,
          $$RestockRequestsTableTableFilterComposer,
          $$RestockRequestsTableTableOrderingComposer,
          $$RestockRequestsTableTableAnnotationComposer,
          $$RestockRequestsTableTableCreateCompanionBuilder,
          $$RestockRequestsTableTableUpdateCompanionBuilder,
          (
            RestockRequestRow,
            BaseReferences<
              _$AppDatabase,
              $RestockRequestsTableTable,
              RestockRequestRow
            >,
          ),
          RestockRequestRow,
          PrefetchHooks Function()
        > {
  $$RestockRequestsTableTableTableManager(
    _$AppDatabase db,
    $RestockRequestsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestockRequestsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestockRequestsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RestockRequestsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<int> requestedQuantity = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> requestedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestockRequestsTableCompanion(
                id: id,
                itemId: itemId,
                itemName: itemName,
                requestedQuantity: requestedQuantity,
                status: status,
                requestedDate: requestedDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String itemName,
                required int requestedQuantity,
                required String status,
                required DateTime requestedDate,
                Value<int> rowid = const Value.absent(),
              }) => RestockRequestsTableCompanion.insert(
                id: id,
                itemId: itemId,
                itemName: itemName,
                requestedQuantity: requestedQuantity,
                status: status,
                requestedDate: requestedDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RestockRequestsTableTable, RestockRequestRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $RestockRequestsTableTable,
                    RestockRequestRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RestockRequestsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RestockRequestsTableTable,
      RestockRequestRow,
      $$RestockRequestsTableTableFilterComposer,
      $$RestockRequestsTableTableOrderingComposer,
      $$RestockRequestsTableTableAnnotationComposer,
      $$RestockRequestsTableTableCreateCompanionBuilder,
      $$RestockRequestsTableTableUpdateCompanionBuilder,
      (
        RestockRequestRow,
        BaseReferences<
          _$AppDatabase,
          $RestockRequestsTableTable,
          RestockRequestRow
        >,
      ),
      RestockRequestRow,
      PrefetchHooks Function()
    >;
typedef $$SchemeApplicationsTableTableCreateCompanionBuilder =
    SchemeApplicationsTableCompanion Function({
      required String schemeId,
      required String status,
      Value<DateTime?> appliedDate,
      Value<int> rowid,
    });
typedef $$SchemeApplicationsTableTableUpdateCompanionBuilder =
    SchemeApplicationsTableCompanion Function({
      Value<String> schemeId,
      Value<String> status,
      Value<DateTime?> appliedDate,
      Value<int> rowid,
    });

class $$SchemeApplicationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchemeApplicationsTableTable> {
  $$SchemeApplicationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get schemeId => $composableBuilder(
    column: $table.schemeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedDate => $composableBuilder(
    column: $table.appliedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemeApplicationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemeApplicationsTableTable> {
  $$SchemeApplicationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get schemeId => $composableBuilder(
    column: $table.schemeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedDate => $composableBuilder(
    column: $table.appliedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemeApplicationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemeApplicationsTableTable> {
  $$SchemeApplicationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get schemeId =>
      $composableBuilder(column: $table.schemeId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedDate => $composableBuilder(
    column: $table.appliedDate,
    builder: (column) => column,
  );
}

class $$SchemeApplicationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemeApplicationsTableTable,
          SchemeApplicationRow,
          $$SchemeApplicationsTableTableFilterComposer,
          $$SchemeApplicationsTableTableOrderingComposer,
          $$SchemeApplicationsTableTableAnnotationComposer,
          $$SchemeApplicationsTableTableCreateCompanionBuilder,
          $$SchemeApplicationsTableTableUpdateCompanionBuilder,
          (
            SchemeApplicationRow,
            BaseReferences<
              _$AppDatabase,
              $SchemeApplicationsTableTable,
              SchemeApplicationRow
            >,
          ),
          SchemeApplicationRow,
          PrefetchHooks Function()
        > {
  $$SchemeApplicationsTableTableTableManager(
    _$AppDatabase db,
    $SchemeApplicationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemeApplicationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SchemeApplicationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SchemeApplicationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> schemeId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> appliedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchemeApplicationsTableCompanion(
                schemeId: schemeId,
                status: status,
                appliedDate: appliedDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String schemeId,
                required String status,
                Value<DateTime?> appliedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchemeApplicationsTableCompanion.insert(
                schemeId: schemeId,
                status: status,
                appliedDate: appliedDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SchemeApplicationsTableTable,
                    SchemeApplicationRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SchemeApplicationsTableTable,
                    SchemeApplicationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemeApplicationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemeApplicationsTableTable,
      SchemeApplicationRow,
      $$SchemeApplicationsTableTableFilterComposer,
      $$SchemeApplicationsTableTableOrderingComposer,
      $$SchemeApplicationsTableTableAnnotationComposer,
      $$SchemeApplicationsTableTableCreateCompanionBuilder,
      $$SchemeApplicationsTableTableUpdateCompanionBuilder,
      (
        SchemeApplicationRow,
        BaseReferences<
          _$AppDatabase,
          $SchemeApplicationsTableTable,
          SchemeApplicationRow
        >,
      ),
      SchemeApplicationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db, _db.ordersTable);
  $$RestockRequestsTableTableTableManager get restockRequestsTable =>
      $$RestockRequestsTableTableTableManager(_db, _db.restockRequestsTable);
  $$SchemeApplicationsTableTableTableManager get schemeApplicationsTable =>
      $$SchemeApplicationsTableTableTableManager(
        _db,
        _db.schemeApplicationsTable,
      );
}
