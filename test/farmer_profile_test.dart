import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/location/place_namer.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/repositories/centers_repository.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/home/presentation/widgets/home_header.dart';
import 'package:khaadsetu_version1/features/farmer/profile/domain/profile_models.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/providers/profile_providers.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/screens/address_form_screen.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/screens/addresses_screen.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/screens/contact_screen.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/screens/farm_details_screen.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/screens/my_activity_screen.dart';

import 'support/farmer_fakes.dart';
import 'support/profile_fakes.dart';

Future<void> pump(
  WidgetTester tester,
  Widget screen, {
  FakeProfileRepository? repo,
  FakeDeviceLocation? gps,
  PlaceName? place,
  FakeCentersRepository? centers,
  List<Override> extra = const [],
  double height = 1800,
}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => screen),
    GoRoute(path: '/farmer/marketplace/location', builder: (context, _) => const Text('village picker')),
    GoRoute(path: '/farmer/profile/addresses/edit', builder: (context, _) => const Text('address form')),
    GoRoute(path: '/farmer/community/post/:id', builder: (context, s) => Text('post ${s.pathParameters['id']}')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repo ?? FakeProfileRepository()),
      deviceLocationProvider.overrideWithValue(gps ?? FakeDeviceLocation(result: shirur)),
      placeNamerProvider.overrideWithValue(FakePlaceNamer(place)),
      centersRepositoryProvider.overrideWithValue(centers ?? FakeCentersRepository()),
      ...extra,
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('where the farmer is, from the phone GPS', () {
    testWidgets('the dashboard shows the place the GPS is in, and no invented village', (tester) async {
      await pump(tester, const Scaffold(body: CurrentLocationLine()), place: const PlaceName(village: 'Kavathe Mahankal', district: 'Sangli'));
      expect(find.text('Kavathe Mahankal, Sangli'), findsOneWidget);
      expect(find.textContaining('Shirur'), findsNothing);
    });

    testWidgets('a GPS fix with no place name still says it is the current location', (tester) async {
      await pump(tester, const Scaffold(body: CurrentLocationLine()));
      expect(find.text('Your current location'), findsOneWidget);
    });

    testWidgets('with no GPS and nothing saved it asks the farmer to set a location', (tester) async {
      await pump(
        tester,
        const Scaffold(body: CurrentLocationLine()),
        gps: FakeDeviceLocation(error: const LocationUnavailable('Location is turned off on this device.')),
      );
      expect(find.text('Set your location'), findsOneWidget);
      await tester.tap(find.byKey(const Key('current-location')));
      await tester.pumpAndSettle();
      expect(find.text('village picker'), findsOneWidget);
    });

    testWidgets('tapping it reads the GPS again', (tester) async {
      final gps = FakeDeviceLocation(result: shirur);
      await pump(tester, const Scaffold(body: CurrentLocationLine()), gps: gps, place: const PlaceName(village: 'Shirur', district: 'Pune'));
      final before = gps.calls;
      await tester.tap(find.byKey(const Key('current-location')));
      await tester.pumpAndSettle();
      expect(gps.calls, before + 1);
    });
  });

  group('addresses', () {
    testWidgets('lists them with the default first, and marks a GPS-pinned one', (tester) async {
      final repo = FakeProfileRepository(addresses: [address('a', label: 'Farm', lat: 18.8), address('b', isDefault: true)]);
      await pump(tester, const AddressesScreen(), repo: repo);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('FARM'), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
      final home = tester.getTopLeft(find.text('HOME')).dy;
      final farm = tester.getTopLeft(find.text('FARM')).dy;
      expect(home, lessThan(farm));
    });

    testWidgets('an empty list invites the first address', (tester) async {
      await pump(tester, const AddressesScreen());
      expect(find.text('No saved addresses yet'), findsOneWidget);
      expect(find.byKey(const Key('add-address')), findsOneWidget);
    });

    testWidgets('make default and delete work from the menu', (tester) async {
      final repo = FakeProfileRepository(addresses: [address('a', isDefault: true), address('b', label: 'Farm')]);
      await pump(tester, const AddressesScreen(), repo: repo);
      await tester.tap(find.byKey(const Key('address-menu-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make default'));
      await tester.pumpAndSettle();
      expect(repo.stored.singleWhere((a) => a.isDefault).addressId, 'b');

      await tester.tap(find.byKey(const Key('address-menu-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(repo.stored.map((a) => a.addressId), ['a']);
      expect(repo.stored.single.isDefault, isTrue);
    });

    testWidgets('in pick mode, tapping returns the address', (tester) async {
      final repo = FakeProfileRepository(addresses: [address('a', isDefault: true)]);
      SavedAddress? picked;
      await pump(
        tester,
        Builder(builder: (context) => Scaffold(body: FilledButton(onPressed: () async => picked = await Navigator.of(context).push<SavedAddress>(MaterialPageRoute(builder: (_) => const AddressesScreen(pick: true))), child: const Text('open')))),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('address-menu-a')), findsNothing);
      await tester.tap(find.text('Asha Patil   9876543210'));
      await tester.pumpAndSettle();
      expect(picked?.addressId, 'a');
    });

    testWidgets('the form fills village, district, PIN and the pin from the phone GPS', (tester) async {
      final repo = FakeProfileRepository(contactInfo: const ContactInfo(phone: '9876543210'));
      await pump(
        tester,
        const AddressFormScreen(),
        repo: repo,
        place: const PlaceName(street: 'Pune-Nagar Road', village: 'Shirur', taluka: 'Shirur', district: 'Pune', pincode: '412210'),
      );
      expect(tester.widget<TextFormField>(find.byKey(const Key('addr-phone'))).controller!.text, '9876543210');
      await tester.tap(find.byKey(const Key('use-my-location')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(find.byKey(const Key('addr-village'))).controller!.text, 'Shirur');
      expect(tester.widget<TextFormField>(find.byKey(const Key('addr-district'))).controller!.text, 'Pune');
      expect(tester.widget<TextFormField>(find.byKey(const Key('addr-pin'))).controller!.text, '412210');
      expect(find.textContaining('GPS: 18.83000, 74.37000'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('addr-name')), 'Asha Patil');
      await tester.enterText(find.byKey(const Key('addr-line1')), 'Gat 12');
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();
      final saved = repo.stored.single;
      expect(saved.latitude, 18.83);
      expect(saved.longitude, 74.37);
      expect(saved.pincode, '412210');
      expect(saved.isDefault, isTrue);
    });

    testWidgets('a phone with GPS off says so and lets the farmer type instead', (tester) async {
      await pump(tester, const AddressFormScreen(), gps: FakeDeviceLocation(error: const LocationUnavailable('Location is turned off on this device.')));
      await tester.tap(find.byKey(const Key('use-my-location')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Location is turned off on this device.'), findsOneWidget);
      expect(find.textContaining('GPS:'), findsNothing);
    });

    testWidgets('bad input is refused before anything is sent', (tester) async {
      final repo = FakeProfileRepository();
      await pump(tester, const AddressFormScreen(), repo: repo);
      await tester.enterText(find.byKey(const Key('addr-name')), 'Asha');
      await tester.enterText(find.byKey(const Key('addr-phone')), 'abc');
      await tester.enterText(find.byKey(const Key('addr-pin')), '12');
      await tester.ensureVisible(find.text('Save address'));
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid mobile number'), findsOneWidget);
      expect(find.text('Enter a 6-digit PIN'), findsOneWidget);
      expect(find.text('Enter the address'), findsOneWidget);
      expect(repo.stored, isEmpty);
    });
  });

  group('contact details', () {
    testWidgets('saves the name, mobile number and email, and shows the login email as fixed', (tester) async {
      final repo = FakeProfileRepository(contactInfo: const ContactInfo(loginEmail: 'asha@login.com'));
      await pump(tester, const ContactScreen(), repo: repo, extra: [
        contactProvider.overrideWith((ref) => ref.watch(profileRepositoryProvider).contact()),
      ]);
      expect(find.textContaining('asha@login.com'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('contact-name')), 'Asha Patil');
      await tester.enterText(find.byKey(const Key('contact-phone')), '+91 98765 43210');
      await tester.enterText(find.byKey(const Key('contact-email')), 'asha@example.com');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.name, 'Asha Patil');
      expect(repo.contactInfo.phone, '+91 98765 43210');
      expect(repo.contactInfo.email, 'asha@example.com');
    });

    testWidgets('an invalid email or number is refused', (tester) async {
      final repo = FakeProfileRepository();
      await pump(tester, const ContactScreen(), repo: repo);
      await tester.enterText(find.byKey(const Key('contact-phone')), '12');
      await tester.enterText(find.byKey(const Key('contact-email')), 'nope');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid mobile number'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(repo.contactInfo.email, '');
    });
  });

  group('community activity', () {
    final activity = MyActivity(
      posts: [ActivityPost(postId: 'p1', title: 'Yellow leaves on soybean', content: 'help', commentCount: 3, likeCount: 2, createdAt: DateTime(2026, 9, 1))],
      replies: [ActivityReply(commentId: 'c1', postId: 'p9', postTitle: 'Pest on cotton', content: 'Try neem oil spray', createdAt: DateTime(2026, 9, 2))],
    );

    testWidgets('shows my posts and my replies, each opening its post', (tester) async {
      await pump(tester, const MyActivityScreen(), repo: FakeProfileRepository(activityData: activity));
      expect(find.text('Posts (1)'), findsOneWidget);
      expect(find.text('Replies (1)'), findsOneWidget);
      expect(find.text('Yellow leaves on soybean'), findsOneWidget);
      expect(find.textContaining('3 answers'), findsOneWidget);
      await tester.tap(find.text('Yellow leaves on soybean'));
      await tester.pumpAndSettle();
      expect(find.text('post p1'), findsOneWidget);
    });

    testWidgets('replies name the post they are under', (tester) async {
      await pump(tester, const MyActivityScreen(), repo: FakeProfileRepository(activityData: activity));
      await tester.tap(find.text('Replies (1)'));
      await tester.pumpAndSettle();
      expect(find.text('On: Pest on cotton'), findsOneWidget);
      expect(find.text('Try neem oil spray'), findsOneWidget);
    });

    testWidgets('a quiet farmer sees an invitation, not a blank page', (tester) async {
      await pump(tester, const MyActivityScreen());
      expect(find.textContaining('not asked anything yet'), findsOneWidget);
    });
  });

  group('farm and scheme details', () {
    testWidgets('answers are stored once on the profile, with the land size', (tester) async {
      final repo = FakeProfileRepository(details: {'hasBankAccount': true});
      await pump(tester, const FarmDetailsScreen(), repo: repo, height: 7000);
      expect(find.byKey(const Key('answered-count')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('land-hectares')), '1.5');
      await tester.ensureVisible(find.byKey(const Key('category-obc')));
      await tester.tap(find.byKey(const Key('category-obc')));
      await tester.ensureVisible(find.byKey(const Key('primaryCrops-Soybean')));
      await tester.tap(find.byKey(const Key('primaryCrops-Soybean')));
      await tester.tap(find.byKey(const Key('primaryCrops-Cotton')));
      await tester.ensureVisible(find.byKey(const Key('hasKcc-no')));
      await tester.tap(find.byKey(const Key('hasKcc-no')));
      await tester.pump();
      await tester.ensureVisible(find.text('Save details'));
      await tester.tap(find.text('Save details'));
      await tester.pumpAndSettle();
      expect(repo.answers['category'], 'obc');
      expect(repo.answers['primaryCrops'], ['Cotton', 'Soybean']);
      expect(repo.answers['hasKcc'], false);
      expect(repo.answers['hasBankAccount'], true, reason: 'earlier answers are kept');
      expect(repo.land, 1.5);
    });

    testWidgets('tapping a chosen answer again forgets it', (tester) async {
      final repo = FakeProfileRepository(details: {'category': 'sc'});
      await pump(tester, const FarmDetailsScreen(), repo: repo, height: 7000);
      await tester.ensureVisible(find.byKey(const Key('category-sc')));
      await tester.tap(find.byKey(const Key('category-sc')));
      await tester.pump();
      await tester.ensureVisible(find.text('Save details'));
      await tester.tap(find.text('Save details'));
      await tester.pumpAndSettle();
      expect(repo.answers.containsKey('category'), isFalse);
    });

    test('every question the screen asks is one the server accepts', () {
      const serverKeys = {
        'category', 'gender', 'dateOfBirth', 'landOwnership', 'nameInLandRecords', 'hasBankAccount', 'hasAadhaar', 'hasKcc', 'hasCropLoan', 'soilType', 'irrigation',
        'primaryCrops', 'ownsPumpset', 'ownsTractor', 'hasSchoolChildren', 'isIncomeTaxPayer', 'isGovtEmployee', 'hasPensionOf10kOrMore',
        'holdsConstitutionalPost', 'isRegisteredProfessional', 'isNri', 'isInstitutionalLandholder', 'practisesOrganic', 'inFarmerGroup',
      };
      expect(allDetailQuestions.map((q) => q.key).toSet().difference(serverKeys), isEmpty);
    });

    test('age is worked out from the date of birth', () {
      expect(const FarmDetails({'dateOfBirth': '1985-06-30'}).age(DateTime(2026, 6, 29)), 40);
      expect(const FarmDetails({'dateOfBirth': '1985-06-30'}).age(DateTime(2026, 6, 30)), 41);
      expect(const FarmDetails().age(), isNull);
    });
  });
}
