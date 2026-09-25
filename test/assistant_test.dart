import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/assistant/domain/assistant_models.dart';
import 'package:khaadsetu_version1/features/assistant/presentation/assistant_providers.dart';
import 'package:khaadsetu_version1/features/assistant/presentation/assistant_screen.dart';

class FakeAssistant implements AssistantRepository {
  FakeAssistant({this.on = true});

  final bool on;
  final asked = <({String message, List<ChatMessage> history})>[];
  final replies = <Object>['Use vermicompost, 2 quintal per acre.'];
  Future<void>? hold;

  @override
  Future<bool> enabled() async => on;

  @override
  Future<String> ask(String message, List<ChatMessage> history) async {
    asked.add((message: message, history: history));
    if (hold != null) await hold;
    final next = replies.length > 1 ? replies.removeAt(0) : replies.first;
    if (next is Exception) throw next;
    return next as String;
  }
}

Future<FakeAssistant> pump(WidgetTester tester, {FakeAssistant? assistant}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = assistant ?? FakeAssistant();
  await tester.pumpWidget(ProviderScope(
    overrides: [assistantRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(theme: AppTheme.light, home: const AssistantScreen()),
  ));
  await tester.pumpAndSettle();
  return fake;
}

Future<void> ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('chat-input')), text);
  await tester.tap(find.byKey(const Key('chat-send')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('the farming assistant', () {
    testWidgets('starts with suggestions in Marathi and English, and a reminder that it can be wrong', (tester) async {
      await pump(tester);
      expect(find.text('Which government schemes fit my farm?'), findsOneWidget);
      expect(find.text('माझ्या सोयाबीनला कोणते सेंद्रिय खत द्यावे?'), findsOneWidget);
      expect(find.textContaining('can make mistakes'), findsOneWidget);
    });

    testWidgets('a question and its answer appear as a conversation', (tester) async {
      final fake = await pump(tester);
      await ask(tester, 'Which fertilizer for soybean?');
      expect(find.text('Which fertilizer for soybean?'), findsOneWidget);
      expect(find.text('Use vermicompost, 2 quintal per acre.'), findsOneWidget);
      expect(fake.asked.single.message, 'Which fertilizer for soybean?');
      expect(fake.asked.single.history, isEmpty);
      expect(find.byKey(const Key('typing')), findsNothing);
    });

    testWidgets('tapping a suggestion asks it', (tester) async {
      final fake = await pump(tester);
      await tester.tap(find.byKey(const Key('suggestion-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(fake.asked.single.message, 'Which government schemes fit my farm?');
      expect(find.byKey(const Key('suggestion-0')), findsNothing, reason: 'the chat replaces the welcome');
    });

    testWidgets('earlier turns go along with the next question, without failed attempts', (tester) async {
      final fake = await pump(tester);
      fake.replies
        ..clear()
        ..add('Which crop?');
      await ask(tester, 'My leaves are yellow');
      await ask(tester, 'Soybean');
      expect(fake.asked.last.message, 'Soybean');
      expect(fake.asked.last.history.map((m) => (m.fromUser, m.text)), [(true, 'My leaves are yellow'), (false, 'Which crop?')]);
    });

    testWidgets('while the answer is being written, dots show and Send is off', (tester) async {
      final fake = await pump(tester);
      final gate = Future<void>.delayed(const Duration(seconds: 2));
      fake.hold = gate;
      await tester.enterText(find.byKey(const Key('chat-input')), 'hello');
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('typing')), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const Key('chat-send'))).onPressed, isNull);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const Key('typing')), findsNothing);
    });

    testWidgets('a failure is shown in the chat, and "Try again" asks the same question', (tester) async {
      final fake = await pump(tester);
      fake.replies
        ..clear()
        ..addAll([Exception('The assistant is busy right now. Please try again in a minute.'), 'Neem cake works well.']);
      await ask(tester, 'Best pest control?');
      expect(find.textContaining('busy right now'), findsOneWidget);
      expect(find.byKey(const Key('chat-retry')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-retry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Neem cake works well.'), findsOneWidget);
      expect(find.textContaining('busy right now'), findsNothing);
      expect(find.text('Best pest control?'), findsOneWidget, reason: 'asked once on screen, not twice');
      expect(fake.asked.map((a) => a.message), ['Best pest control?', 'Best pest control?']);
      expect(fake.asked.last.history, isEmpty, reason: 'the failed try is not part of the conversation');
    });

    testWidgets('an empty message is not sent', (tester) async {
      final fake = await pump(tester);
      await tester.enterText(find.byKey(const Key('chat-input')), '   ');
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pump();
      expect(fake.asked, isEmpty);
    });

    testWidgets('a new chat clears the conversation', (tester) async {
      await pump(tester);
      await ask(tester, 'hello');
      await tester.tap(find.byKey(const Key('clear-chat')));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsNothing);
      expect(find.byKey(const Key('suggestion-0')), findsOneWidget);
    });

    testWidgets('with the assistant off on the server, it says so instead of showing a chat', (tester) async {
      await pump(tester, assistant: FakeAssistant(on: false));
      expect(find.text('The assistant is not available right now'), findsOneWidget);
      expect(find.byKey(const Key('chat-input')), findsNothing);
    });
  });

  test('only the last ten earlier messages are sent as history', () async {
    final fake = FakeAssistant();
    final container = ProviderContainer(overrides: [assistantRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    final chat = container.read(chatControllerProvider.notifier);
    for (var i = 0; i < 8; i++) {
      await chat.send('q$i');
    }
    expect(fake.asked.last.history.length, ChatController.historyLimit);
    expect(container.read(chatControllerProvider).messages.length, 16);
  });
}
