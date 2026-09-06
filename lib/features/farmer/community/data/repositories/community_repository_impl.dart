import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_reply.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_fake_data_source.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  const CommunityRepositoryImpl(this._dataSource);

  final CommunityFakeDataSource _dataSource;

  @override
  Future<List<ForumPost>> getPosts() => _dataSource.fetchPosts();

  @override
  Future<ForumPost> getPostById(String id) => _dataSource.fetchPostById(id);

  @override
  Future<List<ForumReply>> getReplies(String postId) => _dataSource.fetchReplies(postId);
}
