import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/delivery_models.dart';
import '../data/management_api_repository.dart';
import '../domain/management_models.dart';
import '../domain/management_repository.dart';

/// One repository per app: the operator's (their own center) or the admin's (all).
final managementRepositoryProvider = Provider.family<DeliveryManagementRepository, ManagementScope>(
  (ref, scope) => ManagementApiRepository(ref.watch(apiClientProvider), scope),
);

class DeliveriesQuery extends Equatable {
  const DeliveriesQuery(this.scope, this.status);

  final ManagementScope scope;
  final DeliveryStatus? status;

  @override
  List<Object?> get props => [scope, status];
}

final managedDeliveriesProvider = FutureProvider.autoDispose.family<List<ManagedDelivery>, DeliveriesQuery>(
  (ref, q) => ref.watch(managementRepositoryProvider(q.scope)).deliveries(status: q.status),
);

class PartnersQuery extends Equatable {
  const PartnersQuery(this.scope, this.status, [this.query = '']);

  final ManagementScope scope;
  final PartnerStatus? status;
  final String query;

  @override
  List<Object?> get props => [scope, status, query];
}

final managedPartnersProvider = FutureProvider.autoDispose.family<List<PartnerApplication>, PartnersQuery>(
  (ref, q) => ref.watch(managementRepositoryProvider(q.scope)).partners(status: q.status, query: q.query.isEmpty ? null : q.query),
);

class PartnerKey extends Equatable {
  const PartnerKey(this.scope, this.userId);

  final ManagementScope scope;
  final String userId;

  @override
  List<Object?> get props => [scope, userId];
}

final managedPartnerProvider = FutureProvider.autoDispose.family<PartnerApplication, PartnerKey>(
  (ref, k) => ref.watch(managementRepositoryProvider(k.scope)).partner(k.userId),
);

final cashOwedProvider = FutureProvider.autoDispose<List<CashOwed>>(
  (ref) => ref.watch(managementRepositoryProvider(ManagementScope.operator)).cashOwed(),
);

class DocumentKey extends Equatable {
  const DocumentKey(this.scope, this.userId, this.kind);

  final ManagementScope scope;
  final String userId;
  final String kind;

  @override
  List<Object?> get props => [scope, userId, kind];
}

/// A licence or RC photo, fetched once while the review page is open.
final managedDocumentProvider = FutureProvider.autoDispose.family<Uint8List, DocumentKey>(
  (ref, k) => ref.watch(managementRepositoryProvider(k.scope)).document(k.userId, k.kind),
);

/// What the operator's dashboard tile says: how many need a driver, and how many applications wait.
class DeliveryAttention extends Equatable {
  const DeliveryAttention({required this.needDriver, required this.applications});

  final int needDriver;
  final int applications;

  @override
  List<Object?> get props => [needDriver, applications];
}

final operatorDeliveryAttentionProvider = FutureProvider.autoDispose<DeliveryAttention>((ref) async {
  final repo = ref.watch(managementRepositoryProvider(ManagementScope.operator));
  final open = await repo.deliveries(status: DeliveryStatus.open);
  final waiting = await repo.partners(status: PartnerStatus.pending);
  return DeliveryAttention(needDriver: open.where((d) => d.needsDriver).length, applications: waiting.length);
});
