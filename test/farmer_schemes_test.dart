import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/domain/entities/gov_scheme.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/domain/entities/scheme_application.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/domain/entities/scheme_eligibility_result.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/domain/repositories/schemes_repository.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/presentation/providers/schemes_providers.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/presentation/screens/scheme_detail_screen.dart';
import 'package:khaadsetu_version1/features/farmer/schemes/presentation/screens/schemes_list_view.dart';

GovScheme scheme(String id, {String sector = 'Insurance', String level = 'central', String audience = 'farmer', String name = ''}) => GovScheme(
      id: id,
      name: name.isEmpty ? 'Scheme $id' : name,
      agency: 'Ministry',
      category: SchemeCategory.subsidy,
      description: 'About $id',
      benefit: 'Benefit of $id',
      eligibilityCriteria: const ['Own land'],
      maxLandHoldingHectares: null,
      applicationDeadline: null,
      level: level,
      sector: sector,
      audience: audience,
      components: const [SchemeComponent(title: 'Tractor up to 40 HP', assistance: '₹45,000 or 25% of cost')],
      howToApply: 'Apply at your bank',
      contact: 'Taluka Agriculture Officer',
      website: 'pmkisan.gov.in',
    );

SchemeEligibilityResult result(String id, EligibilityStatus status, {int met = 0, int total = 0, List<String> missing = const [], List<EligibilityCheck> checks = const []}) =>
    SchemeEligibilityResult(schemeId: id, status: status, met: met, total: total, missing: missing, checks: checks);

class FakeSchemesRepository implements SchemesRepository {
  FakeSchemesRepository(this.schemes, this.eligibilityById);

  final List<GovScheme> schemes;
  Map<String, SchemeEligibilityResult> eligibilityById;
  final applied = <String>[];
  Object? applyError;

  @override
  Future<List<GovScheme>> getSchemes() async => schemes;

  @override
  Future<GovScheme> getSchemeById(String id) async => schemes.firstWhere((s) => s.id == id);

  @override
  Future<SchemeApplication> getApplicationStatus(String schemeId) async =>
      SchemeApplication(schemeId: schemeId, status: applied.contains(schemeId) ? ApplicationStatus.submitted : ApplicationStatus.notApplied, appliedDate: null);

  @override
  Future<SchemeApplication> applyToScheme(String schemeId) async {
    if (applyError != null) throw applyError!;
    applied.add(schemeId);
    return getApplicationStatus(schemeId);
  }

  @override
  Future<Map<String, SchemeEligibilityResult>> eligibilitySummary() async => eligibilityById;

  @override
  Future<SchemeEligibilityResult> eligibility(String schemeId) async => eligibilityById[schemeId]!;
}

Future<void> pump(WidgetTester tester, Widget screen, FakeSchemesRepository repo, {double height = 2400}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => screen),
    GoRoute(path: '/farmer/community/scheme/:id', builder: (context, s) => SchemeDetailScreen(schemeId: s.pathParameters['id']!)),
    GoRoute(path: '/farmer/profile/farm', builder: (context, _) => const Scaffold(body: Text('farm details'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [schemesRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final schemes = [
    scheme('pmkisan', sector: 'Income support', name: 'PM-KISAN Income Support'),
    scheme('fasal', sector: 'Insurance', name: 'PM Fasal Bima Yojana'),
    scheme('pkvy', sector: 'Soil & fertilizer', level: 'state', name: 'Organic Farming Support'),
    scheme('mega', sector: 'Processing & business', audience: 'enterprise', name: 'Mega Food Park'),
  ];
  final eligibility = {
    'pmkisan': result('pmkisan', EligibilityStatus.eligible, met: 3, total: 3),
    'fasal': result('fasal', EligibilityStatus.possible, met: 1, total: 3, missing: ['landOwnership', 'hasCropLoan']),
    'pkvy': result('pkvy', EligibilityStatus.notEligible, met: 0, total: 1),
    'mega': result('mega', EligibilityStatus.open),
  };

  group('the scheme directory', () {
    testWidgets('lists every scheme with where it comes from and how the farmer stands', (tester) async {
      await pump(tester, const Scaffold(body: SchemesListView()), FakeSchemesRepository(schemes, eligibility));
      expect(find.text('4 schemes'), findsOneWidget);
      expect(find.text('PM-KISAN Income Support'), findsOneWidget);
      expect(find.text('You are eligible'), findsOneWidget);
      expect(find.text('Check eligibility'), findsOneWidget);
      expect(find.text('2 more to answer'), findsOneWidget);
      expect(find.text('Not eligible for you'), findsOneWidget);
      expect(find.text('MAHARASHTRA'), findsOneWidget);
      expect(find.text('BUSINESSES'), findsOneWidget);
      // A scheme for businesses is not judged against a farmer's profile.
      expect(find.text('Open to all'), findsNothing);
    });

    testWidgets('the banner counts the eligible ones and invites the rest of the answers', (tester) async {
      await pump(tester, const Scaffold(body: SchemesListView()), FakeSchemesRepository(schemes, eligibility));
      expect(find.textContaining('Eligible for 1. 1 more could fit'), findsOneWidget);
    });

    testWidgets('search narrows the list', (tester) async {
      await pump(tester, const Scaffold(body: SchemesListView()), FakeSchemesRepository(schemes, eligibility));
      await tester.enterText(find.byKey(const Key('scheme-search')), 'fasal');
      await tester.pump();
      expect(find.text('1 scheme'), findsOneWidget);
      expect(find.text('PM Fasal Bima Yojana'), findsOneWidget);
      expect(find.text('PM-KISAN Income Support'), findsNothing);
      await tester.enterText(find.byKey(const Key('scheme-search')), 'zzz');
      await tester.pump();
      expect(find.text('No schemes match'), findsOneWidget);
    });

    testWidgets('a sector chip filters, and tapping it again clears it', (tester) async {
      await pump(tester, const Scaffold(body: SchemesListView()), FakeSchemesRepository(schemes, eligibility));
      await tester.ensureVisible(find.byKey(const Key('sector-Insurance')));
      await tester.tap(find.byKey(const Key('sector-Insurance')));
      await tester.pump();
      expect(find.text('1 scheme'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sector-Insurance')));
      await tester.tap(find.byKey(const Key('sector-Insurance')));
      await tester.pump();
      expect(find.text('4 schemes'), findsOneWidget);
    });

    testWidgets('"For me" hides what the answers rule out, and what is not for farmers', (tester) async {
      await pump(tester, const Scaffold(body: SchemesListView()), FakeSchemesRepository(schemes, eligibility));
      await tester.tap(find.byKey(const Key('for-me')));
      await tester.pump();
      expect(find.text('2 schemes'), findsOneWidget);
      expect(find.text('Organic Farming Support'), findsNothing);
      expect(find.text('Mega Food Park'), findsNothing);
      expect(find.text('PM-KISAN Income Support'), findsOneWidget);
      expect(find.text('PM Fasal Bima Yojana'), findsOneWidget);
    });
  });

  group('a scheme page', () {
    final checks = [
      const EligibilityCheck(label: 'You own land', status: CheckStatus.met),
      const EligibilityCheck(label: 'No family member paid income tax', status: CheckStatus.notMet),
      const EligibilityCheck(label: 'Your name is in the land records', status: CheckStatus.unknown, needs: 'nameInLandRecords'),
      const EligibilityCheck(label: 'Your crop is notified', status: CheckStatus.info),
    ];

    testWidgets('shows what you get, how to apply, and each rule checked against your answers', (tester) async {
      final repo = FakeSchemesRepository(schemes, {
        'pmkisan': result('pmkisan', EligibilityStatus.notEligible, met: 1, total: 3, missing: ['nameInLandRecords'], checks: checks),
      });
      await pump(tester, const SchemeDetailScreen(schemeId: 'pmkisan'), repo, height: 3200);
      expect(find.text('PM-KISAN Income Support'), findsOneWidget);
      expect(find.text('Central scheme  ·  Income support'), findsOneWidget);
      expect(find.text('Tractor up to 40 HP'), findsOneWidget);
      expect(find.text('₹45,000 or 25% of cost'), findsOneWidget);
      expect(find.text('Apply at your bank'), findsOneWidget);
      expect(find.text('You meet 1 of 3 conditions we can check from your profile.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.text('Your name is in the land records (tell us)'), findsOneWidget);
      expect(find.byKey(const Key('answer-questions')), findsOneWidget);
      // A clear no from the saved answers turns Apply off, with the reason.
      final apply = tester.widget<ElevatedButton>(find.descendant(of: find.byKey(const Key('apply-now')), matching: find.byType(ElevatedButton)));
      expect(apply.onPressed, isNull);
      expect(find.text('Your saved answers do not meet this scheme.'), findsOneWidget);
    });

    testWidgets('answering the open questions re-checks the scheme with the new answers', (tester) async {
      final repo = FakeSchemesRepository(schemes, {
        'fasal': result('fasal', EligibilityStatus.possible, met: 1, total: 2, missing: ['landOwnership'], checks: const [
          EligibilityCheck(label: 'You own land', status: CheckStatus.unknown, needs: 'landOwnership'),
        ]),
      });
      await pump(tester, const SchemeDetailScreen(schemeId: 'fasal'), repo, height: 3200);
      expect(find.text('Answer 1 question to be sure'), findsOneWidget);
      // The farmer fills the answers in on the profile; the server now says eligible.
      repo.eligibilityById = {'fasal': result('fasal', EligibilityStatus.eligible, met: 2, total: 2, checks: const [EligibilityCheck(label: 'You own land', status: CheckStatus.met)])};
      await tester.tap(find.byKey(const Key('answer-questions')));
      await tester.pumpAndSettle();
      expect(find.text('farm details'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(find.text('You are eligible'), findsOneWidget);
      expect(find.byKey(const Key('answer-questions')), findsNothing);
    });

    testWidgets('an eligible farmer can apply, and then sees the status', (tester) async {
      final repo = FakeSchemesRepository(schemes, {
        'pmkisan': result('pmkisan', EligibilityStatus.eligible, met: 1, total: 1, checks: const [EligibilityCheck(label: 'You own land', status: CheckStatus.met)]),
      });
      await pump(tester, const SchemeDetailScreen(schemeId: 'pmkisan'), repo, height: 3200);
      await tester.tap(find.byKey(const Key('apply-now')));
      await tester.pumpAndSettle();
      expect(repo.applied, ['pmkisan']);
      expect(find.text('Submitted'), findsOneWidget);
    });

    testWidgets('a scheme for businesses shows no eligibility check and no apply button', (tester) async {
      final repo = FakeSchemesRepository(schemes, eligibility);
      await pump(tester, const SchemeDetailScreen(schemeId: 'mega'), repo, height: 3200);
      expect(find.byKey(const Key('eligibility-section')), findsNothing);
      expect(find.byKey(const Key('apply-now')), findsNothing);
      expect(find.text('Mega Food Park'), findsOneWidget);
    });
  });

  test('the server answer is read into a result, and an unknown status is treated as "check"', () {
    final r = SchemeEligibilityResult.fromJson({
      'schemeId': 'x',
      'status': 'possible',
      'met': 2,
      'total': 5,
      'missing': ['isNri'],
      'checks': [
        {'label': 'Not an NRI family', 'status': 'unknown', 'needs': 'isNri'},
        {'label': 'Crop is notified', 'status': 'info'},
      ],
    });
    expect(r.status, EligibilityStatus.possible);
    expect(r.missing, ['isNri']);
    expect(r.checks.map((c) => c.status), [CheckStatus.unknown, CheckStatus.info]);
    expect(EligibilityStatus.parse('from-the-future'), EligibilityStatus.possible);
  });
}
