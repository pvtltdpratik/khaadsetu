import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/database_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/datasources/schemes_local_data_source.dart';
import '../../data/repositories/schemes_repository_impl.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';
import '../../domain/repositories/schemes_repository.dart';
import '../../domain/services/scheme_eligibility.dart';

final schemesRepositoryProvider = Provider<SchemesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SchemesRepositoryImpl(SchemesLocalDataSource(db));
});

final schemesProvider = FutureProvider.autoDispose<List<GovScheme>>((ref) {
  return ref.watch(schemesRepositoryProvider).getSchemes();
});

final schemeProvider =
    FutureProvider.autoDispose.family<GovScheme, String>((ref, id) {
  return ref.watch(schemesRepositoryProvider).getSchemeById(id);
});

final schemeApplicationProvider =
    FutureProvider.autoDispose.family<SchemeApplication, String>((ref, schemeId) {
  return ref.watch(schemesRepositoryProvider).getApplicationStatus(schemeId);
});

/// Whether the farmer's profile qualifies for a given scheme's land-holding
/// rule. Depends only on `home`'s public [farmerProfileProvider], not its
/// internals.
final schemeEligibilityProvider =
    FutureProvider.autoDispose.family<bool, GovScheme>((ref, scheme) async {
  final profile = await ref.watch(farmerProfileProvider.future);
  return SchemeEligibility.isEligible(profile, scheme);
});
