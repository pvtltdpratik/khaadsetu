import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/invoices/domain/invoice_models.dart';
import 'package:khaadsetu_version1/features/invoices/domain/invoice_repository.dart';
import 'package:khaadsetu_version1/features/invoices/pdf/invoice_output.dart';
import 'package:khaadsetu_version1/features/invoices/pdf/invoice_pdf.dart';
import 'package:khaadsetu_version1/features/invoices/presentation/closing_and_settings_screens.dart';
import 'package:khaadsetu_version1/features/invoices/presentation/credit_screens.dart';
import 'package:khaadsetu_version1/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:khaadsetu_version1/features/invoices/presentation/invoice_list_screen.dart';
import 'package:khaadsetu_version1/features/invoices/presentation/invoice_providers.dart';

Map<String, dynamic> invoiceJson(
  String id, {
  String number = 'CEN001/2026-27/00001',
  String kind = 'walk_in',
  String status = 'issued',
  double total = 900,
  double paid = 900,
  double due = 0,
  String paymentStatus = 'paid',
  String mode = 'cash',
  String? upi,
  double tax = 0,
  String buyer = 'Ramesh',
  String cancelReason = '',
  String language = 'en',
  List<Map<String, dynamic>>? items,
  List<Map<String, dynamic>> payments = const [],
}) =>
    {
      'id': id,
      'number': number,
      'kind': kind,
      'status': status,
      'seller': {'name': 'Yavatmal Center', 'address': 'Yavatmal', 'phone': '9800000001', 'gstin': '27ABCDE1234F1Z5'},
      'buyer': {'name': buyer, 'village': 'Shirur', 'phone': '9800000002'},
      'items': items ??
          [
            {'name': 'Vermicompost', 'qty': 2, 'unit': '40 kg bag', 'rate': 450, 'discount': 0, 'taxPercent': tax > 0 ? 5 : 0, 'tax': tax, 'amount': 900, 'hsn': '3101'},
          ],
      'subtotal': total,
      'discountTotal': 0,
      'taxTotal': tax,
      'deliveryCharge': 0,
      'platformFee': 0,
      'roundOff': 0,
      'grandTotal': total,
      'amountInWords': 'Rupees Nine Hundred Only',
      'paymentStatus': paymentStatus,
      'paymentMode': mode,
      'paidAmount': paid,
      'balanceDue': due,
      'creditNotesTotal': 0,
      'language': language,
      'issuedAt': '2026-09-26T10:00:00.000Z',
      'dueDate': due > 0 ? '2026-10-15' : null,
      'notes': '',
      'upiUri': upi,
      'cancelReason': cancelReason,
      'payments': payments,
    };

Invoice anInvoice(String id, {String number = 'CEN001/2026-27/00001', String buyer = 'Ramesh', double total = 900, double paid = 900, double due = 0, String paymentStatus = 'paid', String mode = 'cash', String? upi, double tax = 0, String status = 'issued', String cancelReason = '', String kind = 'walk_in', String language = 'en', List<Map<String, dynamic>>? items, List<Map<String, dynamic>> payments = const []}) =>
    Invoice.fromJson(invoiceJson(id, number: number, buyer: buyer, total: total, paid: paid, due: due, paymentStatus: paymentStatus, mode: mode, upi: upi, tax: tax, status: status, cancelReason: cancelReason, kind: kind, language: language, items: items, payments: payments));

class FakeInvoiceRepository implements InvoiceRepository {
  FakeInvoiceRepository({List<Invoice>? invoices}) : invoices = invoices ?? [];

  List<Invoice> invoices;
  final queries = <InvoiceQuery>[];
  final payments = <({String id, double amount, String mode, String reference})>[];
  final cancelled = <({InvoiceScope scope, String id, String reason})>[];
  final returned = <({String id, List<(int, double)> items, String reason})>[];
  final collected = <({String farmer, double amount, String mode})>[];
  final saved = <(String, Map<String, dynamic>)>[];
  final closingDates = <String?>[];
  Object? error;
  CreditBook book = const CreditBook(farmers: [], totalOutstanding: 0);
  CreditAccount? account;
  DailyClosing day = const DailyClosing(date: '2026-09-26', invoices: 3, salesTotal: 2700, cashInHand: 900, upiReceived: 900, cardReceived: 0, creditGiven: 900, creditRecovered: 0, refundedTotal: 0);
  PlatformSettings platform = const PlatformSettings(pricesIncludeTax: true, defaultGst: 0, gstByCategory: {'organic': 0, 'fertilizer': 0, 'seed': 0, 'pesticide': 0, 'equipment': 0}, centerSalesPercent: 5, farmerProductPercent: 5);

  @override
  Future<InvoiceList> list(InvoiceQuery query) async {
    queries.add(query);
    if (error != null) throw error!;
    var items = invoices;
    if (query.paymentStatus != null) items = items.where((i) => i.paymentStatus == query.paymentStatus).toList();
    if (query.search.isNotEmpty) items = items.where((i) => i.number.contains(query.search) || i.buyer.name.toLowerCase().contains(query.search.toLowerCase())).toList();
    return InvoiceList(items: items, summary: InvoiceSummary(count: items.length, total: items.fold(0.0, (s, i) => s + i.grandTotal), due: items.fold(0.0, (s, i) => s + i.balanceDue)));
  }

  @override
  Future<Invoice> get(InvoiceScope scope, String id) async => invoices.firstWhere((i) => i.id == id);

  @override
  Future<Invoice> recordPayment(String id, {required double amount, required String mode, String reference = ''}) async {
    if (error != null) throw error!;
    payments.add((id: id, amount: amount, mode: mode, reference: reference));
    return invoices.firstWhere((i) => i.id == id);
  }

  @override
  Future<Invoice> cancel(InvoiceScope scope, String id, {required String reason}) async {
    if (error != null) throw error!;
    cancelled.add((scope: scope, id: id, reason: reason));
    return invoices.firstWhere((i) => i.id == id);
  }

  @override
  Future<Invoice> returnItems(String id, {required List<(int, double)> items, required String reason}) async {
    if (error != null) throw error!;
    returned.add((id: id, items: items, reason: reason));
    return invoices.firstWhere((i) => i.id == id);
  }

  @override
  Future<Invoice> create(Map<String, dynamic> body) async => invoices.first;

  @override
  Future<CreditBook> creditBook() async => book;

  @override
  Future<CreditAccount> creditAccount(String farmerId) async => account!;

  @override
  Future<void> collectCredit(String farmerId, {required double amount, required String mode, String reference = ''}) async {
    if (error != null) throw error!;
    collected.add((farmer: farmerId, amount: amount, mode: mode));
  }

  @override
  Future<DailyClosing> closing({String? date}) async {
    closingDates.add(date);
    return day;
  }

  @override
  Future<String> exportCsv(InvoiceQuery query) async => 'Invoice,Total\nCEN001/2026-27/00001,900';

  @override
  Future<PlatformSettings> settings() async => platform;

  @override
  Future<void> saveSettings(String key, Map<String, dynamic> changes) async {
    if (error != null) throw error!;
    saved.add((key, changes));
  }
}

class FakeOutput implements InvoiceOutput {
  final printed = <(String, InvoicePaper)>[];
  final shared = <(String, InvoicePaper)>[];
  final csvs = <String>[];

  @override
  Future<void> print(Invoice invoice, InvoicePaper paper) async => printed.add((invoice.number, paper));

  @override
  Future<void> sharePdf(Invoice invoice, InvoicePaper paper) async => shared.add((invoice.number, paper));

  @override
  Future<void> shareCsv(String csv, {String filename = 'invoices.csv'}) async => csvs.add(csv);
}

Future<void> mount(WidgetTester tester, Widget screen, FakeInvoiceRepository repo, {FakeOutput? output, double height = 2400, List<GoRoute> extra = const []}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => screen),
    GoRoute(path: '/operator/dashboard/bills/:id', builder: (context, s) => Text('operator bill ${s.pathParameters['id']}')),
    GoRoute(path: '/farmer/profile/bills/:id', builder: (context, s) => Text('farmer bill ${s.pathParameters['id']}')),
    GoRoute(path: '/admin/overview/invoices/:id', builder: (context, s) => Text('admin bill ${s.pathParameters['id']}')),
    ...extra,
  ]);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [invoiceRepositoryProvider.overrideWithValue(repo), invoiceOutputProvider.overrideWithValue(output ?? FakeOutput())],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('reading a bill from the server', () {
    test('the parts of a bill are read, including who it is from and to, and whether more can be paid', () {
      final i = anInvoice('a', due: 400, paid: 500, paymentStatus: 'partial', upi: 'upi://pay?pa=x');
      expect(i.seller.name, 'Yavatmal Center');
      expect(i.seller.gstin, '27ABCDE1234F1Z5');
      expect(i.buyer.place, 'Shirur');
      expect(i.items.single.name, 'Vermicompost');
      expect(i.items.single.qty, 2);
      expect(i.canTakePayment, isTrue);
      expect(i.canBeCorrected, isTrue);
      expect(anInvoice('b').canTakePayment, isFalse, reason: 'nothing due');
      expect(anInvoice('c', status: 'cancelled', due: 100).canTakePayment, isFalse);
      expect(anInvoice('d', kind: 'credit_note').canBeCorrected, isFalse);
      expect(anInvoice('e', tax: 42.86).hasTax, isTrue);
    });

    test('a filter keeps what was not changed, and knows when nothing is chosen', () {
      const q = InvoiceQuery(scope: InvoiceScope.operator);
      expect(q.isFiltered, isFalse);
      final f = q.copyWith(paymentStatus: 'unpaid', search: ' Ramesh ');
      expect(f.params, {'paymentStatus': 'unpaid', 'q': 'Ramesh'});
      expect(f.copyWith(paymentStatus: null).paymentStatus, isNull);
      expect(f.copyWith(kind: 'sale').paymentStatus, 'unpaid');
      expect(f.scope, InvoiceScope.operator);
      expect(f, const InvoiceQuery(scope: InvoiceScope.operator, paymentStatus: 'unpaid', search: ' Ramesh '));
    });
  });

  group('the PDF', () {
    Future<void> checkPdf(Invoice inv, InvoicePaper paper) async {
      final bytes = await buildInvoicePdf(inv, paper: paper);
      expect(bytes, isA<Uint8List>());
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(800));
    }

    test('is made for an A4 sheet and for both receipt rolls', () async {
      final inv = anInvoice('a', tax: 42.86, due: 400, paid: 500, paymentStatus: 'partial', upi: 'upi://pay?pa=shop%40upi&pn=Shop&am=400.00&cu=INR&tn=X', payments: [
        {'kind': 'payment', 'amount': 500, 'mode': 'cash', 'reference': '', 'paidAt': '2026-09-26T10:00:00.000Z'},
      ]);
      for (final paper in InvoicePaper.values) {
        await checkPdf(inv, paper);
      }
    });

    test('copes with a cancelled bill, a credit note, many lines and long names', () async {
      await checkPdf(anInvoice('c', status: 'cancelled', cancelReason: 'Wrong bill', paymentStatus: 'refunded'), InvoicePaper.a4);
      await checkPdf(anInvoice('n', kind: 'credit_note'), InvoicePaper.roll80);
      final many = [for (var i = 0; i < 60; i++) {'name': 'A very long product name number $i that goes on and on', 'qty': 1.5, 'unit': 'kg', 'rate': 123.45, 'discount': 0, 'taxPercent': 0, 'tax': 0, 'amount': 185.18, 'hsn': ''}];
      await checkPdf(anInvoice('m', items: many, total: 11110.8), InvoicePaper.a4);
    });

    test('Marathi and Hindi fall back to English without a Devanagari font, and use their own words with one', () {
      expect(InvoiceWords.forLanguage('mr', devanagari: false)['thanks'], 'Thank you for your business.');
      expect(InvoiceWords.forLanguage('mr', devanagari: true)['thanks'], 'धन्यवाद! पुन्हा भेट द्या.');
      expect(InvoiceWords.forLanguage('hi', devanagari: true)['total'], 'कुल देय');
      expect(InvoiceWords.forLanguage('en', devanagari: true)['total'], 'Grand total');
      expect(InvoiceWords.forLanguage('mr', devanagari: true)['hsn'], 'HSN', reason: 'a word with no translation uses the English one');
    });

    test('paper sizes: a sheet and two rolls', () {
      expect(InvoicePaper.a4.isRoll, isFalse);
      expect(InvoicePaper.roll80.isRoll, isTrue);
      expect(InvoicePaper.roll80.format.width, closeTo(226.8, 0.5), reason: '80 mm in points');
      expect(InvoicePaper.roll58.format.width, closeTo(164.4, 0.5), reason: '58 mm in points');
    });
  });

  group('the list of bills', () {
    final bills = [
      anInvoice('1', number: 'CEN001/2026-27/00001', buyer: 'Ramesh'),
      anInvoice('2', number: 'CEN001/2026-27/00002', buyer: 'Sunita', paymentStatus: 'unpaid', paid: 0, due: 900, mode: 'credit'),
      anInvoice('3', number: 'CEN001/2026-27/00003', buyer: 'Anil', paymentStatus: 'partial', paid: 400, due: 500),
    ];

    testWidgets('shows each bill with who, what, when and how much, and a summary', (tester) async {
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.operator), FakeInvoiceRepository(invoices: bills));
      expect(find.text('CEN001/2026-27/00001'), findsOneWidget);
      expect(find.textContaining('Ramesh  ·  Counter sale  ·  26/09/2026'), findsOneWidget);
      expect(find.text('3 bills  ·  ₹2,700'), findsOneWidget);
      expect(find.text('₹1,400 due'), findsOneWidget);
      expect(find.text('Unpaid'), findsWidgets);
      expect(find.text('Part paid'), findsWidgets);
    });

    testWidgets('the payment chips filter the list on the server', (tester) async {
      final repo = FakeInvoiceRepository(invoices: bills);
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.operator), repo);
      await tester.tap(find.byKey(const Key('pay-unpaid')));
      await tester.pumpAndSettle();
      expect(repo.queries.last.paymentStatus, 'unpaid');
      expect(find.text('CEN001/2026-27/00002'), findsOneWidget);
      expect(find.text('CEN001/2026-27/00001'), findsNothing);
      await tester.tap(find.byKey(const Key('pay-all')));
      await tester.pumpAndSettle();
      expect(find.text('CEN001/2026-27/00001'), findsOneWidget);
    });

    testWidgets('searching by name or number', (tester) async {
      final repo = FakeInvoiceRepository(invoices: bills);
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.operator), repo);
      await tester.enterText(find.byKey(const Key('invoice-search')), 'sunita');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(repo.queries.last.search, 'sunita');
      expect(find.text('CEN001/2026-27/00002'), findsOneWidget);
      expect(find.text('CEN001/2026-27/00003'), findsNothing);
    });

    testWidgets('a farmer has no search box, an empty list explains itself, and a filter with no match says so', (tester) async {
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.farmer), FakeInvoiceRepository());
      expect(find.byKey(const Key('invoice-search')), findsNothing);
      expect(find.textContaining('No bills yet'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('pay-paid')));
      await tester.tap(find.byKey(const Key('pay-paid')));
      await tester.pumpAndSettle();
      expect(find.textContaining('No bills match'), findsOneWidget);
    });

    testWidgets('tapping a bill opens it, on the right page for who is looking', (tester) async {
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.operator), FakeInvoiceRepository(invoices: bills));
      await tester.tap(find.byKey(const Key('invoice-2')));
      await tester.pumpAndSettle();
      expect(find.text('operator bill 2'), findsOneWidget);
    });

    testWidgets('only the admin can export, and it shares the spreadsheet', (tester) async {
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.operator), FakeInvoiceRepository(invoices: bills));
      expect(find.byKey(const Key('export-invoices')), findsNothing);
      final out = FakeOutput();
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.admin), FakeInvoiceRepository(invoices: bills), output: out);
      await tester.tap(find.byKey(const Key('export-invoices')));
      await tester.pumpAndSettle();
      expect(out.csvs.single, contains('CEN001/2026-27/00001'));
    });

    testWidgets('a server error can be retried', (tester) async {
      final repo = FakeInvoiceRepository(invoices: bills)..error = 'offline';
      await mount(tester, const InvoiceListScreen(scope: InvoiceScope.farmer), repo);
      expect(find.textContaining('offline'), findsOneWidget);
    });
  });

  group('one bill', () {
    Future<FakeInvoiceRepository> open(WidgetTester tester, Invoice inv, {InvoiceScope scope = InvoiceScope.operator, FakeOutput? out}) async {
      final repo = FakeInvoiceRepository(invoices: [inv]);
      await mount(tester, InvoiceDetailScreen(scope: scope, id: inv.id), repo, output: out);
      return repo;
    }

    testWidgets('is laid out like the paper one: numbers, both parties, lines, totals in figures and words', (tester) async {
      await open(tester, anInvoice('a', tax: 42.86));
      expect(find.text('CEN001/2026-27/00001'), findsOneWidget);
      expect(find.text('Yavatmal Center'), findsOneWidget);
      expect(find.text('GSTIN 27ABCDE1234F1Z5'), findsOneWidget);
      expect(find.text('Ramesh'), findsOneWidget);
      expect(find.text('Vermicompost'), findsOneWidget);
      expect(find.text('2 40 kg bag x ₹450'), findsOneWidget);
      expect(find.textContaining('GST 5% (₹42.86 included)  ·  HSN 3101'), findsOneWidget);
      expect(find.text('Rupees Nine Hundred Only'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('grand-total'))).data, '₹900');
      expect(find.text('Cash'), findsNothing);
      expect(find.textContaining('Paid  ·  Cash'), findsOneWidget);
    });

    testWidgets('an unpaid bill shows what is due, when, and a UPI code to scan', (tester) async {
      await open(tester, anInvoice('a', paid: 0, due: 900, paymentStatus: 'unpaid', mode: 'credit', upi: 'upi://pay?pa=shop%40upi&am=900.00'));
      expect(tester.widget<Text>(find.byKey(const Key('balance-due'))).data, '₹900');
      expect(find.text('Due by'), findsOneWidget);
      expect(find.byKey(const Key('upi-qr')), findsOneWidget);
      expect(find.text('Scan to pay ₹900 by UPI'), findsOneWidget);
    });

    testWidgets('a paid bill has no code and nothing due', (tester) async {
      await open(tester, anInvoice('a'));
      expect(find.byKey(const Key('upi-qr')), findsNothing);
      expect(find.byKey(const Key('balance-due')), findsNothing);
      expect(find.byKey(const Key('record-payment')), findsNothing);
    });

    testWidgets('a cancelled bill says so and why, and offers no payment or correction', (tester) async {
      await open(tester, anInvoice('a', status: 'cancelled', cancelReason: 'Wrong product billed', paymentStatus: 'refunded', due: 0));
      expect(find.text('Cancelled: Wrong product billed'), findsOneWidget);
      expect(find.byKey(const Key('cancel-invoice')), findsNothing);
      expect(find.byKey(const Key('return-items')), findsNothing);
    });

    testWidgets('sharing and printing hand the bill to the phone, on the chosen paper', (tester) async {
      final out = FakeOutput();
      await open(tester, anInvoice('a'), out: out);
      await tester.tap(find.byKey(const Key('share-pdf')));
      await tester.pumpAndSettle();
      expect(out.shared.single, ('CEN001/2026-27/00001', InvoicePaper.a4));
      await tester.tap(find.byKey(const Key('print-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('print-roll80')));
      await tester.pumpAndSettle();
      expect(out.printed.single, ('CEN001/2026-27/00001', InvoicePaper.roll80));
    });

    testWidgets('a farmer can share and print but not take payments or change the bill', (tester) async {
      await open(tester, anInvoice('a', paid: 0, due: 900, paymentStatus: 'unpaid'), scope: InvoiceScope.farmer);
      expect(find.byKey(const Key('share-pdf')), findsOneWidget);
      expect(find.byKey(const Key('record-payment')), findsNothing);
      expect(find.byKey(const Key('cancel-invoice')), findsNothing);
      expect(find.byKey(const Key('return-items')), findsNothing);
    });

    testWidgets('the operator takes a payment: checked, then sent with its mode and reference', (tester) async {
      final repo = await open(tester, anInvoice('a', paid: 0, due: 900, paymentStatus: 'unpaid'));
      await tester.tap(find.byKey(const Key('record-payment')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('pay-amount'))).controller!.text, '900');
      await tester.enterText(find.byKey(const Key('pay-amount')), '1200');
      await tester.tap(find.byKey(const Key('pay-save')));
      await tester.pump();
      expect(find.byKey(const Key('pay-error')), findsOneWidget, reason: 'more than is due');
      await tester.enterText(find.byKey(const Key('pay-amount')), '400');
      await tester.tap(find.byKey(const Key('mode-upi')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('pay-reference')), 'UTR777');
      await tester.tap(find.byKey(const Key('pay-save')));
      await tester.pumpAndSettle();
      expect(repo.payments.single, (id: 'a', amount: 400.0, mode: 'upi', reference: 'UTR777'));
      expect(find.text('Payment recorded.'), findsOneWidget);
    });

    testWidgets('cancelling needs a reason, and is sent with it', (tester) async {
      final repo = await open(tester, anInvoice('a'));
      await tester.tap(find.byKey(const Key('cancel-invoice')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('reason-confirm'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reason')), 'Billed twice');
      await tester.pump();
      await tester.tap(find.byKey(const Key('reason-confirm')));
      await tester.pumpAndSettle();
      expect(repo.cancelled.single, (scope: InvoiceScope.operator, id: 'a', reason: 'Billed twice'));
    });

    testWidgets('the admin can cancel too, from the admin side', (tester) async {
      final repo = await open(tester, anInvoice('a'), scope: InvoiceScope.admin);
      expect(find.byKey(const Key('return-items')), findsNothing, reason: 'returns are handled at the counter');
      await tester.tap(find.byKey(const Key('cancel-invoice')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reason')), 'Test bill');
      await tester.pump();
      await tester.tap(find.byKey(const Key('reason-confirm')));
      await tester.pumpAndSettle();
      expect(repo.cancelled.single.scope, InvoiceScope.admin);
    });

    testWidgets('goods coming back: choose how many of which, give a reason', (tester) async {
      final repo = await open(tester, anInvoice('a'));
      await tester.tap(find.byKey(const Key('return-items')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('return-save'))).onPressed, isNull, reason: 'nothing chosen yet');
      await tester.tap(find.byKey(const Key('more-0')));
      await tester.pump();
      expect(find.byKey(const Key('back-0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('more-0')));
      await tester.pump();
      expect(tester.widget<IconButton>(find.byKey(const Key('more-0'))).onPressed, isNull, reason: 'only two were sold');
      await tester.tap(find.byKey(const Key('less-0')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('return-reason')), 'Bag was torn');
      await tester.pump();
      await tester.tap(find.byKey(const Key('return-save')));
      await tester.pumpAndSettle();
      expect(repo.returned.single.items, [(0, 1.0)]);
      expect(repo.returned.single.reason, 'Bag was torn');
    });

    testWidgets('a server refusal is shown, not swallowed', (tester) async {
      final repo = await open(tester, anInvoice('a', paid: 0, due: 900, paymentStatus: 'unpaid'));
      repo.error = 'Only Rs 100 is still due on this invoice';
      await tester.tap(find.byKey(const Key('record-payment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-save')));
      await tester.pumpAndSettle();
      expect(find.text('Only Rs 100 is still due on this invoice'), findsOneWidget);
    });
  });

  group('the credit book', () {
    CreditAccount account(double balance, {String phone = '98765 43210'}) => CreditAccount(
          farmer: CreditFarmer(farmerId: 'f1', name: 'Sunita', balance: balance, village: 'Shirur', phone: phone),
          balance: balance,
          entries: [CreditEntry(kind: 'credit_given', amount: 900, note: 'On credit: CEN001/2026-27/00002', createdAt: DateTime(2026, 9, 26))],
          dueInvoices: [anInvoice('2', number: 'CEN001/2026-27/00002', paid: 0, due: balance, paymentStatus: 'unpaid', mode: 'credit')],
        );

    testWidgets('lists who owes what, largest first, with the total', (tester) async {
      final repo = FakeInvoiceRepository()
        ..book = const CreditBook(totalOutstanding: 1400, farmers: [
          CreditFarmer(farmerId: 'f1', name: 'Sunita', balance: 900, village: 'Shirur', phone: '9800000002'),
          CreditFarmer(farmerId: 'f2', name: 'Anil', balance: 500),
        ]);
      String? opened;
      await mount(tester, CreditBookScreen(onOpenFarmer: (context, id) => opened = id), repo);
      expect(find.text('₹1,400'), findsOneWidget);
      expect(find.text('owed to you by 2 farmers'), findsOneWidget);
      expect(find.text('Sunita'), findsOneWidget);
      expect(find.text('₹900'), findsOneWidget);
      await tester.tap(find.byKey(const Key('credit-f1')));
      expect(opened, 'f1');
    });

    testWidgets('an empty book says so', (tester) async {
      await mount(tester, CreditBookScreen(onOpenFarmer: (_, _) {}), FakeInvoiceRepository());
      expect(find.byKey(const Key('credit-empty')), findsOneWidget);
    });

    testWidgets('a farmer\'s account: balance, unpaid bills, history; collecting checks the amount and sends it', (tester) async {
      final repo = FakeInvoiceRepository()..account = account(900);
      await mount(tester, const CreditAccountScreen(farmerId: 'f1'), repo);
      expect(tester.widget<Text>(find.byKey(const Key('account-balance'))).data, '₹900');
      expect(find.text('CEN001/2026-27/00002'), findsWidgets);
      expect(find.text('On credit: CEN001/2026-27/00002'), findsOneWidget);
      await tester.tap(find.byKey(const Key('collect')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('collect-amount')), '1000');
      await tester.tap(find.byKey(const Key('collect-save')));
      await tester.pump();
      expect(find.byKey(const Key('collect-error')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('collect-amount')), '300');
      await tester.tap(find.byKey(const Key('collect-mode-upi')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('collect-save')));
      await tester.pumpAndSettle();
      expect(repo.collected.single, (farmer: 'f1', amount: 300.0, mode: 'upi'));
    });

    testWidgets('the WhatsApp reminder opens a chat with the right number and words', (tester) async {
      Uri? opened;
      final repo = FakeInvoiceRepository()..account = account(900);
      await mount(tester, CreditAccountScreen(farmerId: 'f1', centerName: 'Yavatmal Center', launcher: (uri) async { opened = uri; return true; }), repo);
      await tester.tap(find.byKey(const Key('remind')));
      await tester.pump();
      expect(opened!.host, 'wa.me');
      expect(opened!.path, '/919876543210', reason: 'ten digits get the Indian country code, spaces are dropped');
      expect(opened!.queryParameters['text'], contains('₹900'));
      expect(opened!.queryParameters['text'], contains('Sunita'));
      expect(opened!.queryParameters['text'], contains('Yavatmal Center'));
    });

    testWidgets('someone who owes nothing has no collect or remind buttons', (tester) async {
      final repo = FakeInvoiceRepository()..account = account(0);
      await mount(tester, const CreditAccountScreen(farmerId: 'f1'), repo);
      expect(find.byKey(const Key('collect')), findsNothing);
      expect(find.byKey(const Key('remind')), findsNothing);
      expect(find.text('nothing owed'), findsOneWidget);
    });

    test('phone numbers become WhatsApp addresses whatever way they were typed', () {
      Uri link(String phone) => whatsAppReminder(phone: phone, name: 'A', due: 100);
      expect(link('9876543210').path, '/919876543210');
      expect(link('+91 98765-43210').path, '/919876543210');
      expect(link('919876543210').path, '/919876543210');
    });
  });

  group('the day closing', () {
    testWidgets('shows the day at a glance, and today by default', (tester) async {
      final repo = FakeInvoiceRepository();
      await mount(tester, const DailyClosingScreen(), repo);
      expect(repo.closingDates.first, isNull);
      expect(find.text('2026-09-26'), findsOneWidget);
      expect(find.text('3 bills made'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('sales'))).data, '₹2,700');
      expect(tester.widget<Text>(find.byKey(const Key('cash'))).data, '₹900');
      expect(tester.widget<Text>(find.byKey(const Key('upi'))).data, '₹900');
      expect(tester.widget<Text>(find.byKey(const Key('credit-given'))).data, '₹900');
      expect(tester.widget<Text>(find.byKey(const Key('credit-recovered'))).data, '₹0');
      expect(find.byKey(const Key('refunded')), findsNothing);
    });

    testWidgets('refunds appear only when there were some', (tester) async {
      final repo = FakeInvoiceRepository()..day = const DailyClosing(date: '2026-09-26', invoices: 1, salesTotal: 900, cashInHand: 450, upiReceived: 0, cardReceived: 0, creditGiven: 0, creditRecovered: 0, refundedTotal: 450);
      await mount(tester, const DailyClosingScreen(), repo);
      expect(find.text('Refunded today: ₹450'), findsOneWidget);
    });
  });

  group('the admin settings', () {
    testWidgets('load the current rates, and save the ones changed to the server', (tester) async {
      final repo = FakeInvoiceRepository();
      await mount(tester, const PlatformSettingsScreen(), repo);
      expect(tester.widget<TextField>(find.byKey(const Key('rate-organic'))).controller!.text, '0');
      expect(tester.widget<TextField>(find.byKey(const Key('rate-center'))).controller!.text, '5');
      await tester.enterText(find.byKey(const Key('rate-organic')), '5');
      await tester.enterText(find.byKey(const Key('rate-farmer')), '7.5');
      await tester.ensureVisible(find.byKey(const Key('save-settings')));
      await tester.tap(find.byKey(const Key('save-settings')));
      await tester.pumpAndSettle();
      expect(repo.saved.length, 2);
      final tax = repo.saved.firstWhere((s) => s.$1 == 'tax').$2;
      expect((tax['gstPercent'] as Map)['organic'], 5.0);
      expect((tax['gstPercent'] as Map)['seed'], 0.0);
      expect(tax['pricesIncludeTax'], isTrue);
      final commission = repo.saved.firstWhere((s) => s.$1 == 'commission').$2;
      expect(commission['farmerProductPercent'], 7.5);
      expect(commission['centerSalesPercent'], 5.0);
    });

    testWidgets('a rate that is not a number from 0 to 100 is refused before anything is sent', (tester) async {
      final repo = FakeInvoiceRepository();
      await mount(tester, const PlatformSettingsScreen(), repo);
      await tester.enterText(find.byKey(const Key('rate-seed')), '150');
      await tester.ensureVisible(find.byKey(const Key('save-settings')));
      await tester.tap(find.byKey(const Key('save-settings')));
      await tester.pump();
      expect(find.byKey(const Key('settings-error')), findsOneWidget);
      expect(repo.saved, isEmpty);
    });

    testWidgets('the tax switch is sent too', (tester) async {
      final repo = FakeInvoiceRepository();
      await mount(tester, const PlatformSettingsScreen(), repo);
      await tester.tap(find.byKey(const Key('includes-tax')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('save-settings')));
      await tester.tap(find.byKey(const Key('save-settings')));
      await tester.pumpAndSettle();
      expect(repo.saved.firstWhere((s) => s.$1 == 'tax').$2['pricesIncludeTax'], isFalse);
    });
  });
}
