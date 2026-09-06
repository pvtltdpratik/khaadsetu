import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/community_fake_data_source.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_reply.dart';
import '../../domain/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(CommunityFakeDataSource());
});

final forumPostsProvider = FutureProvider.autoDispose<List<ForumPost>>((ref) {
  return ref.watch(communityRepositoryProvider).getPosts();
});

final forumPostProvider =
    FutureProvider.autoDispose.family<ForumPost, String>((ref, id) {
  return ref.watch(communityRepositoryProvider).getPostById(id);
});

final forumRepliesProvider =
    FutureProvider.autoDispose.family<List<ForumReply>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).getReplies(postId);
});
