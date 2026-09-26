import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/price_format.dart';
import '../domain/invoice_models.dart';

/// A bill as plain text for a thermal printer: [columns] characters wide (32 on a 58 mm roll, 48 on an 80 mm roll).
/// Plain English letters only, because most cheap printers have no Devanagari font; the PDF has the full language.
String receiptText(Invoice inv, {int columns = 32}) {
  final line = '-' * columns;
  String center(String s) => s.length >= columns ? s : '${' ' * ((columns - s.length) ~/ 2)}$s';
  String two(String left, String right) {
    final room = columns - right.length - 1;
    final l = left.length > room ? left.substring(0, room < 1 ? 0 : room) : left;
    return '$l${' ' * (columns - l.length - right.length)}$right';
  }

  String ascii(String s) => s.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
  // A long name goes on to the next line instead of running off the paper.
  String wrap(String s) => [for (var i = 0; i < s.length; i += columns) s.substring(i, i + columns > s.length ? s.length : i + columns)].join('\n');
  final b = StringBuffer()
    ..writeln(wrap(ascii(inv.seller.name)))
    ..writeln(wrap(ascii([inv.seller.village, inv.seller.phone].where((s) => s.isNotEmpty).join(' '))));
  if (inv.seller.gstin.isNotEmpty) b.writeln(center('GSTIN ${inv.seller.gstin}'));
  b
    ..writeln(line)
    ..writeln(two(inv.isCreditNote ? 'CREDIT NOTE' : 'BILL', ascii(inv.number.split('/').last)))
    ..writeln(wrap(ascii(inv.number)))
    ..writeln('${inv.issuedAt.day.toString().padLeft(2, '0')}/${inv.issuedAt.month.toString().padLeft(2, '0')}/${inv.issuedAt.year} ${inv.issuedAt.hour.toString().padLeft(2, '0')}:${inv.issuedAt.minute.toString().padLeft(2, '0')}');
  if (inv.buyer.name.isNotEmpty) b.writeln(wrap('To: ${ascii(inv.buyer.name)}'));
  b.writeln(line);
  for (final i in inv.items) {
    b
      ..writeln(wrap(ascii(i.name)))
      ..writeln(two('  ${_n(i.qty)} ${i.unit} x ${formatRupeesExact(i.rate).replaceAll('₹', '')}', formatRupeesExact(i.amount).replaceAll('₹', '')));
  }
  b.writeln(line);
  if (inv.discountTotal > 0) b.writeln(two('Discount', '-${_m(inv.discountTotal)}'));
  if (inv.taxTotal > 0) b.writeln(two('Tax included', _m(inv.taxTotal)));
  if (inv.deliveryCharge > 0) b.writeln(two('Delivery', _m(inv.deliveryCharge)));
  if (inv.platformFee > 0) b.writeln(two('Platform fee', _m(inv.platformFee)));
  b
    ..writeln(two('TOTAL', 'Rs ${_m(inv.grandTotal)}'))
    ..writeln(two('Paid (${ascii(inv.paymentMode.isEmpty ? '-' : inv.paymentMode)})', _m(inv.paidAmount)));
  if (inv.balanceDue > 0) b.writeln(two('DUE', _m(inv.balanceDue)));
  b
    ..writeln(line)
    ..writeln(center('Thank you'))
    ..writeln(center('ShetSamrudhi'))
    ..writeln()
    ..writeln();
  return b.toString();
}

String _m(double v) => formatRupeesExact(v).replaceAll('₹', '');
String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// The link that hands text to the RawBT app, which prints on the paired Bluetooth printer.
Uri rawBtUri(String text) => Uri.parse('rawbt:base64,${base64.encode(utf8.encode(text))}');

/// Opens RawBT with a receipt. False when the app is not installed. A seam so tests need no phone.
typedef ReceiptLauncher = Future<bool> Function(Uri uri);

final receiptLauncherProvider = Provider<ReceiptLauncher>((ref) => (uri) async {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    });
