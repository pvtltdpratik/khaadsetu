import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialler for [phone]. Says so when the device can't.
Future<void> callPhone(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  await _launch(context, Uri(scheme: 'tel', path: digits), "Couldn't open the phone app. The number is $phone.");
}

/// Shows a place in the device's maps app (or the browser).
Future<void> openInMaps(BuildContext context, {required double latitude, required double longitude}) async {
  final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$latitude,$longitude'});
  await _launch(context, uri, "Couldn't open the map.");
}

Future<void> _launch(BuildContext context, Uri uri, String failure) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "24 Sep".
String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]}';
