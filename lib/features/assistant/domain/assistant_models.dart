import 'package:equatable/equatable.dart';

/// A screen the assistant points at: tapping it takes the farmer straight there.
class ChatAction extends Equatable {
  const ChatAction({required this.label, required this.route});

  factory ChatAction.fromJson(Map<String, dynamic> json) => ChatAction(label: json['label'] as String, route: json['route'] as String);

  final String label;
  final String route;

  @override
  List<Object?> get props => [label, route];
}

/// One message in the conversation with the farming assistant.
class ChatMessage extends Equatable {
  const ChatMessage({required this.fromUser, required this.text, this.isError = false, this.action});

  final bool fromUser;
  final String text;

  /// A failure worded for the farmer (shown in the chat, with a retry), not an answer.
  final bool isError;

  /// Set when the answer points at a specific screen in the app.
  final ChatAction? action;

  Map<String, String> toHistory() => {'role': fromUser ? 'user' : 'model', 'text': text};

  @override
  List<Object?> get props => [fromUser, text, isError, action];
}

/// What the assistant sent back: the words, and optionally a screen to jump to.
class ChatAnswer extends Equatable {
  const ChatAnswer({required this.text, this.action});

  final String text;
  final ChatAction? action;

  @override
  List<Object?> get props => [text, action];
}

abstract class AssistantRepository {
  /// Whether the server has the assistant switched on.
  Future<bool> enabled();

  /// Sends [message] with the recent conversation and returns the answer.
  Future<ChatAnswer> ask(String message, List<ChatMessage> history);
}
