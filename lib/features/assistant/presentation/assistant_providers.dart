import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../data/assistant_api_repository.dart';
import '../domain/assistant_models.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) => AssistantApiRepository(ref.watch(apiClientProvider)));

/// Whether to offer the assistant at all. If the server cannot be asked, it is not offered.
final assistantEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await ref.watch(assistantRepositoryProvider).enabled();
  } catch (_) {
    return false;
  }
});

class ChatState {
  const ChatState({this.messages = const [], this.sending = false});

  final List<ChatMessage> messages;
  final bool sending;

  ChatState copyWith({List<ChatMessage>? messages, bool? sending}) => ChatState(messages: messages ?? this.messages, sending: sending ?? this.sending);
}

/// The conversation. It lasts while the app is open and is not saved anywhere else.
class ChatController extends Notifier<ChatState> {
  /// How many earlier messages go along with a question (the server also caps it).
  static const historyLimit = 10;

  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.sending) return;
    // Earlier answers only: failed attempts are not part of the conversation.
    final history = [for (final m in state.messages) if (!m.isError) m];
    state = state.copyWith(messages: [...state.messages, ChatMessage(fromUser: true, text: message)], sending: true);
    try {
      final reply = await ref.read(assistantRepositoryProvider).ask(message, history.length > historyLimit ? history.sublist(history.length - historyLimit) : history);
      state = state.copyWith(messages: [...state.messages, ChatMessage(fromUser: false, text: reply)], sending: false);
    } catch (err) {
      state = state.copyWith(messages: [...state.messages, ChatMessage(fromUser: false, text: '$err', isError: true)], sending: false);
    }
  }

  /// Asks the last question again after a failure.
  Future<void> retry() async {
    if (state.sending || state.messages.isEmpty || !state.messages.last.isError) return;
    final withoutError = state.messages.sublist(0, state.messages.length - 1);
    final lastQuestion = withoutError.isNotEmpty && withoutError.last.fromUser ? withoutError.last.text : null;
    if (lastQuestion == null) return;
    state = state.copyWith(messages: withoutError.sublist(0, withoutError.length - 1));
    await send(lastQuestion);
  }

  void clear() => state = const ChatState();
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
