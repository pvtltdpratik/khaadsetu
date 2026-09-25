import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/profile_api_repository.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileApiRepository(ref.watch(apiClientProvider)));

final contactProvider = FutureProvider.autoDispose<ContactInfo>((ref) => ref.watch(profileRepositoryProvider).contact());

final addressesProvider = FutureProvider.autoDispose<List<SavedAddress>>((ref) => ref.watch(profileRepositoryProvider).addresses());

final myActivityProvider = FutureProvider.autoDispose<MyActivity>((ref) => ref.watch(profileRepositoryProvider).activity());

final farmDetailsProvider = FutureProvider.autoDispose<FarmDetails>((ref) => ref.watch(profileRepositoryProvider).details());
