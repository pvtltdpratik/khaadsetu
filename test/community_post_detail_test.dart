import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/community/domain/entities/community_post.dart';
import 'package:khaadsetu_version1/features/farmer/community/domain/entities/post_comment.dart';
import 'package:khaadsetu_version1/features/farmer/community/domain/repositories/community_repository.dart';
import 'package:khaadsetu_version1/features/farmer/community/presentation/providers/community_providers.dart';
import 'package:khaadsetu_version1/features/farmer/community/presentation/screens/post_detail_screen.dart';

final _post = CommunityPost(
  postId: 'p1',
  farmerId: 'f1',
  farmerName: 'Ramesh Patil',
  title: 'Yellowing leaves on wheat',
  content: 'The lower leaves have turned pale yellow.',
  cropTag: 'Wheat',
  districtTag: 'Pune',
  problemTypeTag: ProblemType.nutrientDeficiency,
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
  commentCount: 3,
  likeCount: 4,
);

PostComment _comment(String id, {bool ai = false, bool verified = false, String? agro, String name = 'Sunil P.', String text = 'A reply'}) =>
    PostComment(
      commentId: id,
      postId: 'p1',
      farmerName: name,
      content: text,
      isAiGenerated: ai,
      isAgronomistVerified: verified,
      agronomistName: agro,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

class _FakeRepository implements CommunityRepository {
  _FakeRepository({this.failComment = false});

  final bool failComment;
  bool liked = false;
  int likes = 4;

  @override
  Future<PostDetail> getPostDetail(String postId) async => PostDetail(
        post: _post,
        likedByMe: liked,
        comments: [
          _comment('c1', ai: true, text: 'AI draft text'),
          _comment('c2', ai: true, verified: true, agro: 'Dr. Sanjay', name: 'Dr. Sanjay', text: 'Reviewed answer'),
          _comment('c3', text: 'Plain farmer reply'),
        ],
      );

  @override
  Future<({bool liked, int likeCount})> toggleLike(String postId) async {
    liked = !liked;
    likes += liked ? 1 : -1;
    return (liked: liked, likeCount: likes);
  }

  @override
  Future<PostComment> addComment(String postId, String content) async {
    if (failComment) throw Exception('Network down');
    return _comment('c4', name: 'Me', text: content);
  }

  @override
  Future<CommunityPost> createPost({required String title, required String content, required String cropTag, required String districtTag, required ProblemType problemTypeTag}) =>
      throw UnimplementedError();

  @override
  Future<List<CommunityPost>> getPosts({String? crop, String? district, ProblemType? problemType, String? q, int limit = 20, int offset = 0}) async => [_post];
}

Future<void> _pump(WidgetTester tester, _FakeRepository repo, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [communityRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(theme: AppTheme.light, home: const PostDetailScreen(postId: 'p1')),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mobile: stacked layout shows post, tags, and every kind of comment badge', (tester) async {
    await _pump(tester, _FakeRepository(), size: const Size(400, 800));

    expect(find.text('Yellowing leaves on wheat'), findsOneWidget);
    expect(find.text('Wheat'), findsOneWidget);
    expect(find.text('Pune'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing, reason: 'no side panel on mobile');

    expect(find.text('AI-generated'), findsNWidgets(2));
    expect(find.text('Awaiting expert review'), findsOneWidget);
    expect(find.text('Verified by Dr. Sanjay'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.text('Plain farmer reply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop: post and thread sit side by side', (tester) async {
    await _pump(tester, _FakeRepository(), size: const Size(1280, 800));

    expect(find.byType(VerticalDivider), findsOneWidget);
    final postX = tester.getTopLeft(find.text('Yellowing leaves on wheat')).dx;
    final threadX = tester.getTopLeft(find.text('Reviewed answer')).dx;
    expect(threadX, greaterThan(postX + 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('like button toggles state and count from the server response', (tester) async {
    await _pump(tester, _FakeRepository(), size: const Size(400, 800));

    expect(find.text('4'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('sending a comment appends it and clears the box', (tester) async {
    await _pump(tester, _FakeRepository(), size: const Size(400, 800));

    // Send is disabled until there is something to send.
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded)).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Try neem oil');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Try neem oil'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(find.text('Answers & comments (4)'), findsOneWidget);
  });

  testWidgets('a failed comment keeps the typed text and shows the error', (tester) async {
    await _pump(tester, _FakeRepository(failComment: true), size: const Size(400, 800));

    await tester.enterText(find.byType(TextField), 'Try neem oil');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Network down'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Try neem oil');
    expect(find.text('Answers & comments (3)'), findsOneWidget);
  });
}
