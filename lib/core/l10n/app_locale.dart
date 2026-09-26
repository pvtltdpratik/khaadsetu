import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

/// The languages the app speaks. The person picks one once; it is remembered on the phone.
enum AppLocale {
  en('English', 'en'),
  mr('मराठी', 'mr'),
  hi('हिन्दी', 'hi');

  const AppLocale(this.label, this.code);

  final String label;
  final String code;

  Locale get locale => Locale(code);

  static AppLocale fromCode(String? code) => values.firstWhere((l) => l.code == code, orElse: () => AppLocale.en);
}

const _prefKey = 'app_language';

class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    _load();
    return AppLocale.en;
  }

  Future<void> _load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_prefKey);
      if (saved != null) state = AppLocale.fromCode(saved);
    } catch (_) {
      // No saved choice: English.
    }
  }

  Future<void> choose(AppLocale locale) async {
    state = locale;
    try {
      await (await SharedPreferences.getInstance()).setString(_prefKey, locale.code);
    } catch (_) {
      // The choice still applies until the app closes.
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

/// A text that shows in the person's language when we have it, and as written otherwise. Being a widget (not a function),
/// it can sit inside `const` trees and follows a language change by itself.
class Tx extends StatelessWidget {
  const Tx(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(context.t(text), style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
}

extension TranslateContext on BuildContext {
  /// Looks the text up for the language of this screen (which is what makes it follow a language change).
  String t(String english) => translate(Localizations.localeOf(this).languageCode, english);
}

/// A row that opens the language choice.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return ListTile(
      key: const Key('language-tile'),
      leading: const Icon(Icons.translate),
      title: const Tx('Language'),
      subtitle: Text(current.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final l in AppLocale.values)
              ListTile(
                key: Key('language-${l.code}'),
                title: Text(l.label),
                trailing: l == current ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).choose(l);
                  Navigator.pop(sheet);
                },
              ),
          ]),
        ),
      ),
    );
  }
}
