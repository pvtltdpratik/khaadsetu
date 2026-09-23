import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/operator_center_api_repository.dart';
import '../../domain/entities/operator_center.dart';
import '../../domain/repositories/operator_center_repository.dart';

final operatorCenterRepositoryProvider =
    Provider<OperatorCenterRepository>((ref) => OperatorCenterApiRepository(ref.watch(apiClientProvider)));

final operatorCenterProvider =
    FutureProvider.autoDispose<OperatorCenter>((ref) => ref.watch(operatorCenterRepositoryProvider).center());
