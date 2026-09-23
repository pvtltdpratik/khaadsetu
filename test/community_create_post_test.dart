import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/community/domain/entities/community_post.dart';
import 'package:khaadsetu_version1/features/farmer/community/domain/entities/post_comment.dart';
import 'package:khaadsetu_version1/features/farmer/community/domain/repositories/community_repository.dart';
import 'package:khaadsetu_version1/features/farmer/community/presentation/providers/community_providers.dart';
import 'package:khaadsetu_version1/features/farmer/community/presentation/screens/create_post_screen.dart';

class _FakeRepository implements CommunityRepository {
  _FakeRepository({this.fail = false});

  final bool fail;
  final created = <Map<String, String>>[];
  int feedFetches = 0;

  @override
  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String cropTag,
    required String districtTag,
    required ProblemType problemTypeTag,
  }) async {
    if (fail) throw Exception('Server unavailable');
    created.add({'title': title, 'content': content, 'crop': cropTag, 'district': districtTag, 'type': problemTypeTag.name});
    return CommunityPost(
      postId: 'new',
      farmerId: 'me',
      farmerName: 'Me',
      title: title,
      content: content,
      cropTag: cropTag,
      districtTag: districtTag,
      problemTypeTag: problemTypeTag,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      commentCount: 1,
      likeCount: 0,
    );
  }

  @override
  Future<List<CommunityPost>> getPosts({String? crop, String? district, ProblemType? problemType, String? q, int limit = 20, int offset = 0}) async {
    feedFetches++;
    return [];
  }

  @override
  Future<PostDetail> getPostDetail(String postId) => throw UnimplementedError();

  @override
  Future<PostComment> addComment(String postId, String content) => throw UnimplementedError();

  @override
  Future<({bool liked, int likeCount})> toggleLike(String postId) => throw UnimplementedError();
}

/// Mounts the form as a pushed route above a stand-in feed, so "navigates
/// back on success" is observable as the form disappearing.
Future<ProviderContainer> _pump(WidgetTester tester, _FakeRepository repo, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => Scaffold(body: TextButton(onPressed: () => context.push('/new'), child: const Text('open form'))), routes: [
      GoRoute(path: 'new', builder: (context, _) => const CreatePostScreen()),
    ]),
  ]);
  final container = ProviderContainer(overrides: [communityRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.tap(find.text('open form'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _pick(WidgetTester tester, String field, String option) async {
  await tester.ensureVisible(find.text(field));
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Yellow leaves on wheat');
  await tester.enterText(find.widgetWithText(TextFormField, 'Details'), 'Lower leaves are turning pale yellow.');
  await _pick(tester, 'Problem type', 'Nutrient');
  await _pick(tester, 'Crop', 'Wheat');
  await _pick(tester, 'District', 'Pune');
}

void main() {
  testWidgets('submitting an empty form shows every validation error and sends nothing', (tester) async {
    final repo = _FakeRepository();
    await _pump(tester, repo, size: const Size(400, 900));

    await tester.tap(find.text('Publish post'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter a description'), findsOneWidget);
    expect(find.text('Select a problem type'), findsOneWidget);
    expect(find.text('Select a crop'), findsOneWidget);
    expect(find.text('Select a district'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('too-short text is rejected with the server minimum', (tester) async {
    final repo = _FakeRepository();
    await _pump(tester, repo, size: const Size(400, 900));

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'abc');
    await tester.tap(find.text('Publish post'));
    await tester.pumpAndSettle();

    expect(find.text('Write at least 5 characters'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('a valid post is sent with the chosen tags, refreshes the feed, and returns', (tester) async {
    final repo = _FakeRepository();
    await _pump(tester, repo, size: const Size(400, 900));

    await _fillValid(tester);
    await tester.ensureVisible(find.text('Publish post'));
    await tester.tap(find.text('Publish post'));
    await tester.pumpAndSettle();

    expect(repo.created, [
      {'title': 'Yellow leaves on wheat', 'content': 'Lower leaves are turning pale yellow.', 'crop': 'Wheat', 'district': 'Pune', 'type': 'nutrientDeficiency'},
    ]);
    expect(find.text('open form'), findsOneWidget, reason: 'popped back');
    expect(find.text('Post published'), findsOneWidget);
    expect(repo.feedFetches, greaterThan(0), reason: 'feed was reloaded');
  });

  testWidgets('a failed submit stays on the form with the input intact', (tester) async {
    final repo = _FakeRepository(fail: true);
    await _pump(tester, repo, size: const Size(400, 900));

    await _fillValid(tester);
    await tester.ensureVisible(find.text('Publish post'));
    await tester.tap(find.text('Publish post'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Server unavailable'), findsOneWidget);
    expect(find.text('open form'), findsNothing);
    expect(find.text('Yellow leaves on wheat'), findsOneWidget);
    expect(find.text('Publish post'), findsOneWidget, reason: 'button re-enabled for retry');
  });

  testWidgets('desktop lays the three selectors in one row', (tester) async {
    await _pump(tester, _FakeRepository(), size: const Size(1280, 900));

    final crop = tester.getTopLeft(find.text('Crop')).dy;
    final district = tester.getTopLeft(find.text('District')).dy;
    expect(district, crop);
    expect(tester.takeException(), isNull);
  });
}
