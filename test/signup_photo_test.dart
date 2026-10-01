import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/document_picker.dart';

import 'resale_farmer_test.dart' show FakePhotoPicker;

/// The sign-up form's photo is entirely local until the account is actually created (nothing here calls
/// Supabase), so this only exercises picking, replacing and removing it, not submitting the form.
Future<void> pump(WidgetTester tester, FakePhotoPicker picker) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [documentPickerProvider.overrideWithValue(picker)],
    child: const MaterialApp(home: SignUpScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with nothing chosen yet, a plain icon invites a photo', (tester) async {
    await pump(tester, FakePhotoPicker());
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Add a photo (optional)'), findsOneWidget);
  });

  testWidgets('taking a photo replaces the icon, and it can be removed again', (tester) async {
    final picker = FakePhotoPicker();
    await pump(tester, picker);
    await tester.tap(find.byKey(const Key('signup-photo')));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsNothing, reason: 'nothing chosen yet, so nothing to remove');
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(picker.calls, 1);
    expect(find.byIcon(Icons.person_outline), findsNothing);

    await tester.tap(find.byKey(const Key('signup-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
