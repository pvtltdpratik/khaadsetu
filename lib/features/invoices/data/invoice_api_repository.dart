import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/invoice_models.dart';
import '../domain/invoice_repository.dart';

class InvoiceApiRepository implements InvoiceRepository {
  const InvoiceApiRepository(this._api);

  final ApiClient _api;

  static String _enc(String v) => Uri.encodeComponent(v);

  @override
  Future<InvoiceList> list(InvoiceQuery query) async => InvoiceList.fromJson(await _api.get(query.scope.path, query: query.params) as Map<String, dynamic>);

  @override
  Future<Invoice> get(InvoiceScope scope, String id) async => Invoice.fromJson(await _api.get('${scope.path}/${_enc(id)}') as Map<String, dynamic>);

  @override
  Future<Invoice> recordPayment(String id, {required double amount, required String mode, String reference = ''}) async =>
      Invoice.fromJson(await _api.post('/v1/operator/invoices/${_enc(id)}/payments', body: {'amount': amount, 'mode': mode, if (reference.isNotEmpty) 'reference': reference}) as Map<String, dynamic>);

  @override
  Future<Invoice> cancel(InvoiceScope scope, String id, {required String reason}) async =>
      Invoice.fromJson(await _api.post('${scope.path}/${_enc(id)}/cancel', body: {'reason': reason}) as Map<String, dynamic>);

  @override
  Future<Invoice> returnItems(String id, {required List<(int, double)> items, required String reason}) async {
    final out = await _api.post('/v1/operator/invoices/${_enc(id)}/return', body: {
      'reason': reason,
      'items': [for (final (index, qty) in items) {'index': index, 'qty': qty}],
    }) as Map<String, dynamic>;
    return Invoice.fromJson((out['invoice'] as Map).cast<String, dynamic>());
  }

  @override
  Future<Invoice> create(Map<String, dynamic> body) async => Invoice.fromJson(await _api.post('/v1/operator/invoices', body: body) as Map<String, dynamic>);

  @override
  Future<CreditBook> creditBook() async => CreditBook.fromJson(await _api.get('/v1/operator/credit') as Map<String, dynamic>);

  @override
  Future<CreditAccount> creditAccount(String farmerId) async => CreditAccount.fromJson(await _api.get('/v1/operator/credit/${_enc(farmerId)}') as Map<String, dynamic>);

  @override
  Future<void> collectCredit(String farmerId, {required double amount, required String mode, String reference = ''}) async {
    await _api.post('/v1/operator/credit/${_enc(farmerId)}/payments', body: {'amount': amount, 'mode': mode, if (reference.isNotEmpty) 'reference': reference});
  }

  @override
  Future<DailyClosing> closing({String? date}) async => DailyClosing.fromJson(await _api.get('/v1/operator/closing', query: {'date': date}) as Map<String, dynamic>);

  @override
  Future<String> exportCsv(InvoiceQuery query) async => utf8.decode(await _api.getBytes('/v1/admin/invoices/export.csv', query: query.params));

  @override
  Future<PlatformSettings> settings() async => PlatformSettings.fromJson(await _api.get('/v1/admin/settings') as Map<String, dynamic>);

  @override
  Future<void> saveSettings(String key, Map<String, dynamic> changes) async {
    await _api.put('/v1/admin/settings/${_enc(key)}', body: changes);
  }
}
