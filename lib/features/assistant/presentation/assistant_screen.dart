import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animation/fade_slide_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/assistant_models.dart';
import 'assistant_providers.dart';

const _suggestions = [
  'Which government schemes fit my farm?',
  'माझ्या सोयाबीनला कोणते सेंद्रिय खत द्यावे?',
  'How do I read my soil scan?',
  'पिकावर पिवळी पाने का येतात?',
  'How can I get PGS organic certification?',
];

/// Ask anything about crops, soil, fertilizer or schemes, in Marathi, Hindi or English.
/// Answers come from the server's assistant, which knows what the farmer saved in the app.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty) return;
    _input.clear();
    final future = ref.read(chatControllerProvider.notifier).send(message);
    _toBottom();
    await future;
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chat = ref.watch(chatControllerProvider);
    final enabled = ref.watch(assistantEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farming assistant'),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(key: const Key('clear-chat'), tooltip: 'New chat', icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(chatControllerProvider.notifier).clear()),
        ],
      ),
      body: SafeArea(
        child: enabled.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _Off(),
          data: (on) {
            if (!on) return const _Off();
            return Column(children: [
              Expanded(
                child: chat.messages.isEmpty
                    ? _Welcome(onPick: _send)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: chat.messages.length + (chat.sending ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == chat.messages.length) return const _Typing();
                          final m = chat.messages[i];
                          return _Bubble(message: m, onRetry: m.isError && i == chat.messages.length - 1 ? () => ref.read(chatControllerProvider.notifier).retry() : null);
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat-input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Ask about crops, soil, schemes…', counterText: ''),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(key: const Key('chat-send'), onPressed: chat.sending ? null : _send, icon: const Icon(Icons.send_rounded)),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Off extends StatelessWidget {
  const _Off();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.smart_toy_outlined, size: 56, color: context.colors.textMuted),
            AppSpacing.gapMd,
            Text('The assistant is not available right now', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text('You can still ask other farmers in the Community tab.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted)),
          ]),
        ),
      );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppSpacing.gapLg,
        Center(child: CircleAvatar(radius: 34, backgroundColor: colors.primaryContainer, child: Icon(Icons.smart_toy_outlined, size: 36, color: colors.primary))),
        AppSpacing.gapMd,
        Text('नमस्कार! How can I help your farm today?', textAlign: TextAlign.center, style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Ask in Marathi, Hindi or English. I know your land, crops and soil scan from your profile.', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: colors.textMuted)),
        AppSpacing.gapLg,
        for (var i = 0; i < _suggestions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FadeSlideIn(
              index: i,
              child: OutlinedButton(
                key: Key('suggestion-$i'),
                style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(AppSpacing.md)),
                onPressed: () => onPick(_suggestions[i]),
                child: Text(_suggestions[i]),
              ),
            ),
          ),
        AppSpacing.gapSm,
        Text('The assistant can make mistakes. For serious crop or animal problems, also ask your Taluka Agriculture Officer or call the Kisan Call Center on 1800-180-1551.', textAlign: TextAlign.center, style: text.labelSmall?.copyWith(color: colors.textMuted)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final mine = message.fromUser;
    final bg = message.isError ? colors.danger.withValues(alpha: 0.1) : (mine ? colors.primary : colors.surfaceSunken);
    final fg = message.isError ? colors.danger : (mine ? colors.onPrimary : colors.textPrimary);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SelectableText(message.text, style: text.bodyMedium?.copyWith(color: fg)),
          if (onRetry != null) TextButton(key: const Key('chat-retry'), onPressed: onRetry, child: const Text('Try again')),
        ]),
      ),
    );
  }
}

/// Three dots that rise in turn while the answer is being written.
class _Typing extends StatefulWidget {
  const _Typing();

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('typing'),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(16)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 7,
                height: 7,
                margin: EdgeInsets.only(right: i == 2 ? 0 : 4, bottom: 4 * (1 + math.sin(_c.value * 2 * math.pi - i * 1.2)) / 2),
                decoration: BoxDecoration(color: colors.textMuted, shape: BoxShape.circle),
              ),
          ]),
        ),
      ),
    );
  }
}
