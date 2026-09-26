import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/invoice_models.dart';

/// The paper an invoice is printed on: a normal A4 sheet, or a narrow roll for the small receipt printers most shops use.
enum InvoicePaper {
  a4('A4 sheet'),
  roll80('Receipt roll, 80 mm'),
  roll58('Receipt roll, 58 mm');

  const InvoicePaper(this.label);

  final String label;

  bool get isRoll => this != InvoicePaper.a4;

  PdfPageFormat get format => switch (this) {
        InvoicePaper.a4 => PdfPageFormat.a4,
        InvoicePaper.roll80 => const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm),
        InvoicePaper.roll58 => const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm),
      };
}

/// The words on a bill, in the language chosen for it. Devanagari needs a font that has it, so Marathi and Hindi are
/// only used when one could be loaded; otherwise the bill is printed in English rather than with empty boxes.
class InvoiceWords {
  const InvoiceWords(this._t);

  final Map<String, String> _t;

  String operator [](String key) => _t[key] ?? _english._t[key] ?? key;

  static const _english = InvoiceWords({
    'invoice': 'Invoice',
    'creditNote': 'Credit Note',
    'number': 'Invoice No.',
    'date': 'Date',
    'seller': 'Seller',
    'buyer': 'Buyer',
    'item': 'Item',
    'hsn': 'HSN',
    'qty': 'Qty',
    'rate': 'Rate',
    'amount': 'Amount',
    'subtotal': 'Subtotal',
    'discount': 'Discount',
    'tax': 'Tax included',
    'delivery': 'Delivery',
    'fee': 'Service fee',
    'roundOff': 'Round off',
    'total': 'Grand total',
    'words': 'Amount in words',
    'status': 'Payment',
    'mode': 'Mode',
    'paid': 'Paid',
    'due': 'Balance due',
    'dueDate': 'Due by',
    'scan': 'Scan to pay by UPI',
    'thanks': 'Thank you for your business.',
    'sign': 'Authorised signature',
    'cancelled': 'CANCELLED',
    'gstin': 'GSTIN',
    'p.paid': 'Paid',
    'p.unpaid': 'Unpaid',
    'p.partial': 'Part paid',
    'p.refunded': 'Refunded',
    'p.cancelled': 'Cancelled',
  });

  static const _marathi = InvoiceWords({
    'invoice': 'बिल',
    'creditNote': 'क्रेडिट नोट',
    'number': 'बिल क्र.',
    'date': 'दिनांक',
    'seller': 'विक्रेता',
    'buyer': 'खरेदीदार',
    'item': 'वस्तू',
    'qty': 'प्रमाण',
    'rate': 'दर',
    'amount': 'रक्कम',
    'subtotal': 'एकूण',
    'discount': 'सवलत',
    'tax': 'कर (समाविष्ट)',
    'delivery': 'वाहतूक',
    'fee': 'सेवा शुल्क',
    'roundOff': 'पूर्णांक',
    'total': 'एकूण देय',
    'words': 'अक्षरी रक्कम',
    'status': 'देयक स्थिती',
    'mode': 'पद्धत',
    'paid': 'भरले',
    'due': 'बाकी',
    'dueDate': 'देय तारीख',
    'scan': 'UPI ने पैसे भरण्यासाठी स्कॅन करा',
    'thanks': 'धन्यवाद! पुन्हा भेट द्या.',
    'sign': 'अधिकृत स्वाक्षरी',
    'cancelled': 'रद्द',
    'p.paid': 'भरले',
    'p.unpaid': 'बाकी',
    'p.partial': 'अंशतः भरले',
    'p.refunded': 'परत केले',
    'p.cancelled': 'रद्द',
  });

  static const _hindi = InvoiceWords({
    'invoice': 'बिल',
    'creditNote': 'क्रेडिट नोट',
    'number': 'बिल संख्या',
    'date': 'दिनांक',
    'seller': 'विक्रेता',
    'buyer': 'खरीदार',
    'item': 'सामान',
    'qty': 'मात्रा',
    'rate': 'दर',
    'amount': 'राशि',
    'subtotal': 'उप-योग',
    'discount': 'छूट',
    'tax': 'कर (शामिल)',
    'delivery': 'ढुलाई',
    'fee': 'सेवा शुल्क',
    'roundOff': 'पूर्णांक',
    'total': 'कुल देय',
    'words': 'शब्दों में राशि',
    'status': 'भुगतान स्थिति',
    'mode': 'तरीका',
    'paid': 'भुगतान किया',
    'due': 'बकाया',
    'dueDate': 'देय तिथि',
    'scan': 'UPI से भुगतान के लिए स्कैन करें',
    'thanks': 'धन्यवाद! फिर पधारें।',
    'sign': 'अधिकृत हस्ताक्षर',
    'cancelled': 'रद्द',
    'p.paid': 'भुगतान हुआ',
    'p.unpaid': 'बाकी',
    'p.partial': 'आंशिक',
    'p.refunded': 'वापस',
    'p.cancelled': 'रद्द',
  });

  static InvoiceWords forLanguage(String language, {required bool devanagari}) => switch (language) {
        'mr' when devanagari => _marathi,
        'hi' when devanagari => _hindi,
        _ => _english,
      };
}

/// Fonts for the PDF. The built-in ones cover English; [devanagari] is set when the fonts given cover Marathi and Hindi.
class InvoiceFonts {
  const InvoiceFonts({this.regular, this.bold, this.devanagari = false});

  final pw.Font? regular;
  final pw.Font? bold;
  final bool devanagari;
}

String _rs(double v) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  // Indian grouping: 12,34,567.
  final head = digits.length > 3 ? digits.substring(0, digits.length - 3) : '';
  final tail = digits.length > 3 ? digits.substring(digits.length - 3) : digits;
  final grouped = head.isEmpty ? tail : '${head.replaceAllMapped(RegExp(r'(\d)(?=(\d\d)+$)'), (m) => '${m[1]},')},$tail';
  return 'Rs $grouped.${parts[1]}';
}

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _qty(double q) => q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

/// The invoice as a PDF, ready to print, save or share.
Future<Uint8List> buildInvoicePdf(Invoice invoice, {InvoicePaper paper = InvoicePaper.a4, InvoiceFonts fonts = const InvoiceFonts()}) async {
  final w = InvoiceWords.forLanguage(invoice.language, devanagari: fonts.devanagari);
  final theme = fonts.regular == null ? pw.ThemeData() : pw.ThemeData.withFont(base: fonts.regular!, bold: fonts.bold ?? fonts.regular!);
  final doc = pw.Document(title: invoice.number, author: invoice.seller.name, theme: theme);
  final roll = paper.isRoll;
  final small = paper == InvoicePaper.roll58;
  final base = roll ? (small ? 7.0 : 8.0) : 10.0;

  pw.TextStyle t(double size, {bool bold = false}) => pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
  pw.Widget kv(String k, String v, {bool bold = false, double? size}) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(k, style: t(size ?? base, bold: bold)),
        pw.Text(v, style: t(size ?? base, bold: bold)),
      ]);
  pw.Widget party(String title, InvoiceParty p) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: t(base - 1)),
        pw.Text(p.name, style: t(base + 1, bold: true)),
        if (p.place.isNotEmpty) pw.Text(p.place, style: t(base)),
        if (p.phone.isNotEmpty) pw.Text(p.phone, style: t(base)),
        if (p.gstin.isNotEmpty) pw.Text('${w['gstin']}: ${p.gstin}', style: t(base)),
      ]);

  final title = invoice.isCreditNote ? w['creditNote'] : w['invoice'];
  final statusLine = invoice.isCancelled ? w['cancelled'] : w['p.${invoice.paymentStatus}'];
  final qr = invoice.upiUri == null
      ? null
      : pw.Column(children: [
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: invoice.upiUri!, width: roll ? 90 : 96, height: roll ? 90 : 96),
          pw.SizedBox(height: 2),
          pw.Text(w['scan'], style: t(base - 1)),
        ]);

  final totals = pw.Column(children: [
    kv(w['subtotal'], _rs(invoice.subtotal)),
    if (invoice.discountTotal > 0) kv(w['discount'], '- ${_rs(invoice.discountTotal)}'),
    if (invoice.deliveryCharge > 0) kv(w['delivery'], _rs(invoice.deliveryCharge)),
    if (invoice.platformFee > 0) kv(w['fee'], _rs(invoice.platformFee)),
    if (invoice.hasTax) kv(w['tax'], _rs(invoice.taxTotal)),
    if (invoice.roundOff != 0) kv(w['roundOff'], _rs(invoice.roundOff)),
    pw.Divider(thickness: 0.6),
    kv(w['total'], _rs(invoice.grandTotal), bold: true, size: base + 3),
    pw.SizedBox(height: 3),
    kv(w['paid'], _rs(invoice.paidAmount)),
    if (invoice.balanceDue > 0) kv(w['due'], _rs(invoice.balanceDue), bold: true),
    if (invoice.dueDate != null && invoice.balanceDue > 0) kv(w['dueDate'], _date(invoice.dueDate!)),
  ]);

  final lines = roll
      ? pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          for (final l in invoice.items) ...[
            pw.Text(l.name, style: t(base, bold: true)),
            kv('${_qty(l.qty)} ${l.unit} x ${_rs(l.rate)}', _rs(l.amount)),
            pw.SizedBox(height: 2),
          ],
        ])
      : pw.TableHelper.fromTextArray(
          headers: ['#', w['item'], w['hsn'], w['qty'], w['rate'], w['amount']],
          data: [
            for (var i = 0; i < invoice.items.length; i++)
              ['${i + 1}', invoice.items[i].name, invoice.items[i].hsn, '${_qty(invoice.items[i].qty)} ${invoice.items[i].unit}'.trim(), _rs(invoice.items[i].rate), _rs(invoice.items[i].amount)],
          ],
          headerStyle: t(base, bold: true),
          cellStyle: t(base),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerLeft, 2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight, 5: pw.Alignment.centerRight},
          columnWidths: {0: const pw.FixedColumnWidth(24), 1: const pw.FlexColumnWidth(4), 2: const pw.FlexColumnWidth(1.2), 3: const pw.FlexColumnWidth(1.6), 4: const pw.FlexColumnWidth(1.8), 5: const pw.FlexColumnWidth(2)},
        );

  final body = <pw.Widget>[
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(invoice.seller.name, style: t(base + (roll ? 3 : 8), bold: true)),
        if (invoice.seller.place.isNotEmpty) pw.Text(invoice.seller.place, style: t(base)),
        if (invoice.seller.phone.isNotEmpty) pw.Text(invoice.seller.phone, style: t(base)),
        if (invoice.seller.gstin.isNotEmpty) pw.Text('${w['gstin']}: ${invoice.seller.gstin}', style: t(base)),
      ])),
      if (!roll) pw.Text(title, style: t(base + 10, bold: true)),
    ]),
    if (roll) pw.Center(child: pw.Text(title, style: t(base + 2, bold: true))),
    pw.SizedBox(height: 4),
    pw.Divider(thickness: 0.6),
    kv(w['number'], invoice.number, bold: true),
    kv(w['date'], _date(invoice.issuedAt)),
    kv(w['status'], '$statusLine${invoice.paymentMode.isEmpty ? '' : ' / ${paymentModeLabels[invoice.paymentMode] ?? invoice.paymentMode}'}'),
    pw.SizedBox(height: 6),
    roll ? pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [party(w['buyer'], invoice.buyer)]) : pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(child: party(w['seller'], invoice.seller)),
      pw.Expanded(child: party(w['buyer'], invoice.buyer)),
    ]),
    pw.SizedBox(height: 8),
    lines,
    pw.SizedBox(height: 6),
    roll ? totals : pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Spacer(), pw.SizedBox(width: 230, child: totals)]),
    pw.SizedBox(height: 4),
    pw.Text('${w['words']}: ${invoice.amountInWords}', style: t(base - 0.5)),
    if (invoice.payments.isNotEmpty) ...[
      pw.SizedBox(height: 4),
      for (final p in invoice.payments)
        pw.Text('${_date(p.paidAt)}  ${p.isRefund ? '- ' : ''}${_rs(p.amount)}  ${paymentModeLabels[p.mode] ?? p.mode}${p.reference.isEmpty ? '' : '  (${p.reference})'}', style: t(base - 1)),
    ],
    if (invoice.notes.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Text(invoice.notes, style: t(base - 1))),
    if (qr != null) pw.Padding(padding: const pw.EdgeInsets.only(top: 8), child: pw.Center(child: qr)),
    pw.SizedBox(height: roll ? 8 : 24),
    if (!roll) pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(children: [pw.SizedBox(height: 26), pw.Container(width: 150, height: 0.6, color: PdfColors.grey700), pw.Text(w['sign'], style: t(base - 1))])),
    pw.SizedBox(height: 4),
    pw.Center(child: pw.Text(w['thanks'], style: t(base))),
  ];

  if (roll) {
    doc.addPage(pw.Page(pageFormat: paper.format, build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: body)));
  } else {
    doc.addPage(pw.MultiPage(pageFormat: paper.format, margin: const pw.EdgeInsets.all(32), build: (context) => body));
  }
  return doc.save();
}
