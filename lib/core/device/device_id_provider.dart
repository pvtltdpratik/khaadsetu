import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _deviceIdKey = 'device_id';

/// Stable per-install identifier, generated once and persisted via
/// `shared_preferences`. Used to key the soil-scan backend's per-device
/// history — a single string doesn't need a full database table for it.
final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_deviceIdKey);
  if (existing != null) return existing;

  final generated = const Uuid().v4();
  await prefs.setString(_deviceIdKey, generated);
  return generated;
});
