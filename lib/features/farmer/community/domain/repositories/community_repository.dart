import '../entities/forum_post.dart';
import '../entities/forum_reply.dart';

abstract class CommunityRepository {
  Future<List<ForumPost>> getPosts();
  Future<ForumPost> getPostById(String id);
  Future<List<ForumReply>> getReplies(String postId);
}
