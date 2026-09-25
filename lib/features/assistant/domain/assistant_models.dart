import 'package:equatable/equatable.dart';

/// One message in the conversation with the farming assistant.
class ChatMessage extends Equatable {
  const ChatMessage({required this.fromUser, required this.text, this.isError = false});

  final bool fromUser;
  final String text;

  /// A failure worded for the farmer (shown in the chat, with a retry), not an answer.
  final bool isError;

  Map<String, String> toHistory() => {'role': fromUser ? 'user' : 'model', 'text': text};

  @override
  List<Object?> get props => [fromUser, text, isError];
}

abstract class AssistantRepository {
  /// Whether the server has the assistant switched on.
  Future<bool> enabled();

  /// Sends [message] with the recent conversation and returns the answer.
  Future<String> ask(String message, List<ChatMessage> history);
}
