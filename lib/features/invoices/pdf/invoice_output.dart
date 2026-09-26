import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/invoice_models.dart';
import 'invoice_pdf.dart';

/// What can be done with a finished bill: print it, share it as a PDF (to WhatsApp and the like), share a spreadsheet.
/// Swappable so tests need no printer or share sheet.
abstract class InvoiceOutput {
  Future<void> print(Invoice invoice, InvoicePaper paper);

  Future<void> sharePdf(Invoice invoice, InvoicePaper paper);

  Future<void> shareCsv(String csv, {String filename = 'invoices.csv'});
}

class SystemInvoiceOutput implements InvoiceOutput {
  const SystemInvoiceOutput();

  /// Marathi and Hindi need a font with Devanagari. It is fetched once, and without internet the bill is printed in
  /// English, which the built-in fonts can do.
  Future<InvoiceFonts> _fonts(String language) async {
    if (language == 'en') return const InvoiceFonts();
    try {
      final regular = await PdfGoogleFonts.notoSansDevanagariRegular();
      final bold = await PdfGoogleFonts.notoSansDevanagariBold();
      return InvoiceFonts(regular: regular, bold: bold, devanagari: true);
    } catch (_) {
      return const InvoiceFonts();
    }
  }

  Future<Uint8List> _bytes(Invoice invoice, InvoicePaper paper) async => buildInvoicePdf(invoice, paper: paper, fonts: await _fonts(invoice.language));

  @override
  Future<void> print(Invoice invoice, InvoicePaper paper) async {
    final bytes = await _bytes(invoice, paper);
    await Printing.layoutPdf(
      name: invoice.number.replaceAll('/', '-'),
      format: paper.format,
      onLayout: (_) async => bytes,
      usePrinterSettings: paper.isRoll,
    );
  }

  @override
  Future<void> sharePdf(Invoice invoice, InvoicePaper paper) async {
    final bytes = await _bytes(invoice, paper);
    await Printing.sharePdf(bytes: bytes, filename: '${invoice.number.replaceAll('/', '-')}.pdf');
  }

  @override
  Future<void> shareCsv(String csv, {String filename = 'invoices.csv'}) async {
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(utf8.encode(csv), mimeType: 'text/csv', name: filename)], fileNameOverrides: [filename]));
  }
}

final invoiceOutputProvider = Provider<InvoiceOutput>((ref) => const SystemInvoiceOutput());

