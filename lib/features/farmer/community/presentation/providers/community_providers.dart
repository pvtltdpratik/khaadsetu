import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/community_api_data_source.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/post_comment.dart';
import '../../domain/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(CommunityApiDataSource(ref.watch(apiClientProvider)));
});

/// The feed's active filter selection. `q` isn't exposed by the feed screen
/// yet (no search box in this phase) but the repository already supports it.
class CommunityFilters extends Equatable {
  const CommunityFilters({this.crop, this.district, this.problemType, this.q});

  final String? crop;
  final String? district;
  final ProblemType? problemType;
  final String? q;

  @override
  List<Object?> get props => [crop, district, problemType, q];
}

class CommunityFeedState extends Equatable {
  const CommunityFeedState({
    required this.posts,
    required this.hasMore,
    required this.isLoadingMore,
    required this.filters,
  });

  final List<CommunityPost> posts;

  /// Whether the last page fetched was full — a good-enough signal to try
  /// loading another, without needing the server's total count.
  final bool hasMore;
  final bool isLoadingMore;
  final CommunityFilters filters;

  CommunityFeedState copyWith({List<CommunityPost>? posts, bool? hasMore, bool? isLoadingMore}) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filters: filters,
    );
  }

  @override
  List<Object?> get props => [posts, hasMore, isLoadingMore, filters];
}

/// Owns the feed's pages, filters, and infinite-scroll/refresh state as one
/// unit — a `family` keyed by filters would spin up a whole new provider
/// (and lose all loaded pages) on every chip tap, which isn't what "change
/// the filter" should feel like.
class CommunityFeedNotifier extends AsyncNotifier<CommunityFeedState> {
  static const _pageSize = 20;

  @override
  Future<CommunityFeedState> build() => _fetchFirstPage(const CommunityFilters());

  Future<CommunityFeedState> _fetchFirstPage(CommunityFilters filters) async {
    final posts = await ref.read(communityRepositoryProvider).getPosts(
          crop: filters.crop,
          district: filters.district,
          problemType: filters.problemType,
          q: filters.q,
          limit: _pageSize,
          offset: 0,
        );
    return CommunityFeedState(posts: posts, hasMore: posts.length == _pageSize, isLoadingMore: false, filters: filters);
  }

  /// Replaces the filters and reloads from the first page. Deliberately does
  /// not clear `state` to loading first — the old results stay on screen
  /// until the new ones are ready, instead of flashing an empty/loading feed
  /// on every chip tap.
  Future<void> setFilters(CommunityFilters filters) async {
    state = await AsyncValue.guard(() => _fetchFirstPage(filters));
  }

  /// For pull-to-refresh — same "don't blank the list" reasoning as above;
  /// `RefreshIndicator`'s own spinner is the only loading affordance shown.
  Future<void> refresh() async {
    final filters = state.value?.filters ?? const CommunityFilters();
    state = await AsyncValue.guard(() => _fetchFirstPage(filters));
  }

  /// Swaps one post's server-computed counts in place after a like/comment on
  /// the detail screen, so returning to the feed shows fresh numbers without
  /// re-fetching (which would reset the user's filters and scroll position).
  void patchPost(CommunityPost updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      posts: [for (final p in current.posts) p.postId == updated.postId ? updated : p],
    ));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final more = await ref.read(communityRepositoryProvider).getPosts(
            crop: current.filters.crop,
            district: current.filters.district,
            problemType: current.filters.problemType,
            q: current.filters.q,
            limit: _pageSize,
            offset: current.posts.length,
          );
      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...more],
        hasMore: more.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (_) {
      // Keep what's already loaded visible; just stop the trailing spinner
      // so the user can retry by scrolling again or pulling to refresh.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final communityFeedProvider = AsyncNotifierProvider<CommunityFeedNotifier, CommunityFeedState>(CommunityFeedNotifier.new);

/// One post's detail, comments, and the viewer's like state. Like and comment
/// actions update this state directly from the server's response, and mirror
/// the new counts into the feed.
class PostDetailNotifier extends AsyncNotifier<PostDetail> {
  PostDetailNotifier(this.postId);

  final String postId;

  @override
  Future<PostDetail> build() => ref.read(communityRepositoryProvider).getPostDetail(postId);

  /// Throws on failure so the caller can tell the user.
  Future<void> toggleLike() async {
    final current = state.value;
    if (current == null) return;
    final result = await ref.read(communityRepositoryProvider).toggleLike(postId);
    _emit(PostDetail(
      post: current.post.copyWith(likeCount: result.likeCount),
      comments: current.comments,
      likedByMe: result.liked,
    ));
  }

  /// Throws on failure so the input box can keep the user's text and show why.
  Future<void> addComment(String content) async {
    final comment = await ref.read(communityRepositoryProvider).addComment(postId, content);
    final current = state.value;
    if (current == null) return;
    _emit(PostDetail(
      post: current.post.copyWith(commentCount: current.comments.length + 1),
      comments: [...current.comments, comment],
      likedByMe: current.likedByMe,
    ));
  }

  void _emit(PostDetail detail) {
    state = AsyncData(detail);
    ref.read(communityFeedProvider.notifier).patchPost(detail.post);
  }
}

final postDetailProvider =
    AsyncNotifierProvider.autoDispose.family<PostDetailNotifier, PostDetail, String>(PostDetailNotifier.new);
