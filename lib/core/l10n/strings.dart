import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_mr.dart';

/// English text -> Marathi and Hindi. A text that is not here shows in English, so a missing line is never a blank.
/// Keep the English exactly as written in the screens: that is the key. The three phrase lists live in their own
/// files (strings_en.dart, strings_mr.dart, strings_hi.dart) so a translator can work on one language at a time.
String translate(String languageCode, String english) => _table[languageCode]?[english] ?? english;

/// How many texts a language has, for the test that keeps both languages in step.
int translatedCount(String languageCode) => _table[languageCode]?.length ?? 0;

Set<String> translatedKeys(String languageCode) => (_table[languageCode] ?? const {}).keys.toSet();

/// Every phrase the app knows how to translate, as listed in strings_en.dart.
Set<String> get knownPhrases => enPhrases.toSet();

const _table = <String, Map<String, String>>{'mr': mr, 'hi': hi};
