import '../../../core/network/api_client.dart';
import '../domain/assistant_models.dart';

/// The assistant lives behind the server (`/v1/assistant`): the app never holds an AI key.
class AssistantApiRepository implements AssistantRepository {
  const AssistantApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<bool> enabled() async {
    final json = await _api.get('/v1/assistant/status') as Map<String, dynamic>;
    return json['enabled'] as bool? ?? false;
  }

  @override
  Future<String> ask(String message, List<ChatMessage> history) async {
    final json = await _api.post('/v1/assistant/chat', body: {
      'message': message,
      'history': [for (final m in history) m.toHistory()],
    }) as Map<String, dynamic>;
    return json['reply'] as String;
  }
}
