import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/device_id_provider.dart';
import 'api_client.dart';

/// Shared by every feature's data source. The device id resolves lazily, per
/// request, so building the client never has to wait on `shared_preferences`.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(deviceId: () => ref.read(deviceIdProvider.future));
});
