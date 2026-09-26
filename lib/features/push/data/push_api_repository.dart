import '../../../core/network/api_client.dart';
import '../domain/push_models.dart';
import '../domain/push_repository.dart';

class PushApiRepository implements PushRepository {
  const PushApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> registerDevice({required String token, required String app}) async {
    await _api.post('/v1/devices', body: {'token': token, 'platform': 'android', 'app': app});
  }

  @override
  Future<void> unregisterDevice(String token) async {
    await _api.delete('/v1/devices/${Uri.encodeComponent(token)}');
  }

  @override
  Future<NotificationSettings> settings() async => NotificationSettings.fromJson(await _api.get('/v1/notification-settings') as Map<String, dynamic>);

  @override
  Future<void> setChannel(String channel, {required bool enabled}) async {
    await _api.put('/v1/notification-settings', body: {'channels': {channel: enabled}});
  }

  @override
  Future<void> setQuietHours(QuietHours quiet) async {
    await _api.put('/v1/notification-settings', body: {'quietHours': quiet.toJson()});
  }
}
