import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/l10n/app_locale.dart';
import 'package:khaadsetu_version1/core/l10n/strings.dart';
import 'package:khaadsetu_version1/core/l10n/strings_en.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        theme: AppTheme.light,
        locale: ref.watch(localeProvider).locale,
        supportedLocales: [for (final l in AppLocale.values) l.locale],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: const Scaffold(body: Column(children: [Tx('My vehicles'), LanguageTile(), AppButton(label: 'Save'), Tx('A text nobody translated')])),
      );
}

void main() {
  test('Marathi and Hindi have the same lines, and none is empty', () {
    expect(translatedKeys('mr'), translatedKeys('hi'));
    expect(translatedCount('mr'), greaterThan(80));
    for (final code in ['mr', 'hi']) {
      for (final k in translatedKeys(code)) {
        expect(translate(code, k).trim(), isNotEmpty, reason: '$code: $k');
        expect(translate(code, k), isNot(k), reason: '$code left "$k" in English');
      }
    }
    expect(translate('mr', 'A text nobody translated'), 'A text nobody translated');
    expect(translate('en', 'Save'), 'Save');
  });

  test('strings_en.dart, strings_mr.dart and strings_hi.dart list exactly the same phrases, with no duplicates', () {
    expect(knownPhrases.length, enPhrases.length, reason: 'a phrase is listed twice in strings_en.dart');
    expect(knownPhrases, translatedKeys('mr'));
    expect(knownPhrases, translatedKeys('hi'));
  });

  testWidgets('choosing a language changes the words at once, remembers it, and leaves unknown text alone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: _App()));
    await tester.pumpAndSettle();
    expect(find.text('My vehicles'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-mr')));
    await tester.pumpAndSettle();
    expect(find.text('माझी वाहने'), findsOneWidget);
    expect(find.text('जतन करा'), findsOneWidget);
    expect(find.text('A text nobody translated'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('app_language'), 'mr');

    await tester.tap(find.byKey(const Key('language-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-hi')));
    await tester.pumpAndSettle();
    expect(find.text('मेरे वाहन'), findsOneWidget);
  });

  testWidgets('a saved language is used the next time', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'hi'});
    await tester.pumpWidget(const ProviderScope(child: _App()));
    await tester.pumpAndSettle();
    expect(find.text('मेरे वाहन'), findsOneWidget);
  });
}
