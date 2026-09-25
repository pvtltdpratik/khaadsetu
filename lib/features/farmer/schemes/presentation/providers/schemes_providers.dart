import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/schemes_api_data_source.dart';
import '../../data/repositories/schemes_repository_impl.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';
import '../../domain/entities/scheme_eligibility_result.dart';
import '../../domain/repositories/schemes_repository.dart';

final schemesRepositoryProvider = Provider<SchemesRepository>((ref) {
  return SchemesRepositoryImpl(SchemesApiDataSource(ref.watch(apiClientProvider)));
});

final schemesProvider = FutureProvider.autoDispose<List<GovScheme>>((ref) {
  return ref.watch(schemesRepositoryProvider).getSchemes();
});

final schemeProvider = FutureProvider.autoDispose.family<GovScheme, String>((ref, id) {
  return ref.watch(schemesRepositoryProvider).getSchemeById(id);
});

final schemeApplicationProvider = FutureProvider.autoDispose.family<SchemeApplication, String>((ref, schemeId) {
  return ref.watch(schemesRepositoryProvider).getApplicationStatus(schemeId);
});

/// How the farmer stands on every scheme, by scheme id. Worked out on the server from the
/// answers saved on their profile, so it changes the moment they answer one more question.
final eligibilitySummaryProvider = FutureProvider.autoDispose<Map<String, SchemeEligibilityResult>>((ref) {
  return ref.watch(schemesRepositoryProvider).eligibilitySummary();
});

/// One scheme with each rule spelled out (met, not met, or still to be answered).
final schemeEligibilityProvider = FutureProvider.autoDispose.family<SchemeEligibilityResult, String>((ref, schemeId) {
  return ref.watch(schemesRepositoryProvider).eligibility(schemeId);
});
