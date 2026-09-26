import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/widgets/kit.dart';

/// The "Deliver & Earn" board: every open job with filters, one job before deciding, and taking it or asking to.
class BoardApi {
  const BoardApi(this._api);

  final ApiClient _api;

  Future<Json> board(Map<String, String> filters) async => asJson(await _api.get('/v1/delivery/board', query: {...filters, 'useSaved': 'false'}));

  Future<Json> savedBoard() async => asJson(await _api.get('/v1/delivery/board'));
  Future<Json> job(String id) async => asJson(await _api.get('/v1/delivery/board/${Uri.encodeComponent(id)}'));
  Future<Json> take(String id, {String? vehicleId, String note = ''}) async =>
      asJson(await _api.post('/v1/delivery/board/${Uri.encodeComponent(id)}/take', body: {'vehicleId': ?vehicleId, if (note.isNotEmpty) 'note': note}));
  Future<List<Json>> requests() async => asJsonList(await _api.get('/v1/delivery/board/requests'));
  Future<void> withdraw(String id) async {
    await _api.post('/v1/delivery/board/requests/${Uri.encodeComponent(id)}/withdraw');
  }

  Future<void> savePrefs(Map<String, String> filters) async {
    await _api.put('/v1/delivery/board/prefs', body: filters);
  }
}

final boardApiProvider = Provider<BoardApi>((ref) => BoardApi(ref.watch(apiClientProvider)));

/// The board for one set of filters, written as a query string so the same filters are the same key ('' loads with what
/// the server remembers from last time).
final boardProvider = FutureProvider.autoDispose.family<Json, String>((ref, filters) {
  final api = ref.watch(boardApiProvider);
  return filters.isEmpty ? api.savedBoard() : api.board(Uri.splitQueryString(filters));
});

String encodeFilters(Map<String, String> filters) => Uri(queryParameters: filters.isEmpty ? null : filters).query;

final boardJobProvider = FutureProvider.autoDispose.family<Json, String>((ref, id) => ref.watch(boardApiProvider).job(id));
final myBoardRequestsProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(boardApiProvider).requests());
