import '../../../../core/network/api_client.dart';
import '../domain/entities/surplus_lot.dart';
import '../domain/repositories/surplus_repository.dart';

/// The surplus tools against the real API (`/v1/operator/surplus`).
class SurplusApiRepository implements SurplusRepository {
  const SurplusApiRepository(this._api);

  final ApiClient _api;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  SurplusLot _lot(Object? json) => SurplusLot.fromJson(json as Map<String, dynamic>);

  @override
  Future<List<SurplusLot>> lots() async {
    final list = await _api.get('/v1/operator/surplus', query: {'limit': '200'}) as List;
    return list.map(_lot).toList();
  }

  @override
  Future<SurplusLot> create({
    required String productId,
    required int quantity,
    required double unitPrice,
    required SurplusCondition condition,
    DateTime? bestBefore,
    String? note,
    bool fromShelf = false,
  }) async {
    final trimmed = note?.trim() ?? '';
    return _lot(await _api.post('/v1/operator/surplus', body: {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'condition': condition.api,
      if (bestBefore != null) 'bestBefore': _date(bestBefore),
      if (trimmed.isNotEmpty) 'note': trimmed,
      if (fromShelf) 'fromShelf': true,
    }));
  }

  @override
  Future<SurplusLot> update(String id, {double? unitPrice, String? note}) async {
    return _lot(await _api.patch('/v1/operator/surplus/${Uri.encodeComponent(id)}', body: {
      'unitPrice': ?unitPrice,
      'note': ?note?.trim(),
    }));
  }

  @override
  Future<SurplusLot> withdraw(String id) async =>
      _lot(await _api.post('/v1/operator/surplus/${Uri.encodeComponent(id)}/withdraw'));
}
