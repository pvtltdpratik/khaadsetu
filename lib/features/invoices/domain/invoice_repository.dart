import 'invoice_models.dart';

abstract class InvoiceRepository {
  Future<InvoiceList> list(InvoiceQuery query);

  Future<Invoice> get(InvoiceScope scope, String id);

  /// Money taken against a bill (operator).
  Future<Invoice> recordPayment(String id, {required double amount, required String mode, String reference = ''});

  /// Cancels the bill with a credit note (operator or admin).
  Future<Invoice> cancel(InvoiceScope scope, String id, {required String reason});

  /// Some of the goods coming back: a credit note and the money back (operator). Each entry is (line index, quantity).
  Future<Invoice> returnItems(String id, {required List<(int, double)> items, required String reason});

  /// A bill written by hand: a service for a farmer, or stock bought from a supplier (operator).
  Future<Invoice> create(Map<String, dynamic> body);

  Future<CreditBook> creditBook();
  Future<CreditAccount> creditAccount(String farmerId);
  Future<void> collectCredit(String farmerId, {required double amount, required String mode, String reference = ''});
  Future<DailyClosing> closing({String? date});

  /// The admin's invoice list as a spreadsheet file (CSV text).
  Future<String> exportCsv(InvoiceQuery query);

  Future<PlatformSettings> settings();
  Future<void> saveSettings(String key, Map<String, dynamic> changes);
}
