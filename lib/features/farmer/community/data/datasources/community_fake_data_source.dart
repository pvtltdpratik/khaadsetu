import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_reply.dart';

/// Stands in for a remote community forum API.
class CommunityFakeDataSource {
  static final List<ForumPost> _posts = [
    ForumPost(
      id: 'post-1',
      authorName: 'Ramesh Patil',
      title: 'Yellowing leaves on wheat — nitrogen deficiency?',
      body: 'The lower leaves on my wheat crop have started turning pale '
          'yellow from the tip inward. Soil scan showed low nitrogen last '
          'month. Is a urea top-dressing enough at this stage, or should I '
          'wait for the next irrigation cycle?',
      crop: 'Wheat',
      district: 'Pune',
      problemType: ProblemType.nutrientDeficiency,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      replyCount: 4,
      likeCount: 12,
    ),
    ForumPost(
      id: 'post-2',
      authorName: 'Suresh Jadhav',
      title: 'Best time to spray for bollworm in cotton?',
      body: 'Started seeing small holes in cotton bolls this week. Local '
          'shop suggested a broad-spectrum spray but I want to try the '
          'neem-based option first if the infestation is still early.',
      crop: 'Cotton',
      district: 'Aurangabad',
      problemType: ProblemType.pest,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      replyCount: 7,
      likeCount: 18,
    ),
    ForumPost(
      id: 'post-3',
      authorName: 'Anita Kale',
      title: 'Onion prices crashed this week in Nashik mandi',
      body: 'Got barely half of what I expected at the Lasalgaon market '
          'this week. Anyone holding back their harvest, or is it better to '
          'just sell before it drops further?',
      crop: 'Onion',
      district: 'Nashik',
      problemType: ProblemType.market,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      replyCount: 9,
      likeCount: 24,
    ),
    ForumPost(
      id: 'post-4',
      authorName: 'Vikram Deshmukh',
      title: 'Unseasonal rain damaged my sugarcane — insurance claim process?',
      body: 'Heavy rain and waterlogging flattened part of my sugarcane '
          'field last week. I have Fasal Bima coverage but have never filed '
          'a claim before — what documents did others need?',
      crop: 'Sugarcane',
      district: 'Kolhapur',
      problemType: ProblemType.weather,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      replyCount: 5,
      likeCount: 15,
    ),
    ForumPost(
      id: 'post-5',
      authorName: 'Meera Shinde',
      title: 'White fungus spots on soybean leaves',
      body: 'Noticed powdery white patches spreading across soybean leaves '
          'after the last humid spell. Doesn\'t look like the usual rust — '
          'anyone dealt with something similar this season?',
      crop: 'Soybean',
      district: 'Pune',
      problemType: ProblemType.disease,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      replyCount: 3,
      likeCount: 9,
    ),
    ForumPost(
      id: 'post-6',
      authorName: 'Lakshmi Naik',
      title: 'Anyone using drip irrigation for wheat successfully?',
      body: 'Considering switching from flood irrigation to drip for the '
          'next wheat season to save on water. Would love to hear about '
          'real yield and cost experiences, not just the sales pitch.',
      crop: 'Wheat',
      district: 'Pune',
      problemType: ProblemType.general,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      replyCount: 6,
      likeCount: 21,
    ),
  ];

  static const _replyAuthors = [
    'Sunil P.', 'Anita K.', 'Ravindra J.', 'Meera S.', 'Vikram D.', 'Lakshmi N.',
  ];

  static const _replyTemplates = [
    'Faced the same thing last season — sorting it out early made a big difference.',
    'Worth asking at the local Krishi Vigyan Kendra, they usually know the latest guidance.',
    'I\'d wait a few days and monitor before doing anything drastic.',
    'This happened to my neighbor too — the extension officer helped a lot.',
    'Following this thread, dealing with something similar right now.',
    'Thanks for posting, this is useful for anyone in the area.',
  ];

  Future<List<ForumPost>> fetchPosts() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.unmodifiable(_posts.reversed);
  }

  Future<ForumPost> fetchPostById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _posts.firstWhere((p) => p.id == id);
  }

  Future<List<ForumReply>> fetchReplies(String postId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final post = _posts.firstWhere((p) => p.id == postId);
    final seed = postId.hashCode.abs();
    return List.generate(post.replyCount.clamp(0, 4), (i) {
      final nameIndex = (seed + i) % _replyAuthors.length;
      // Stride 1 (not e.g. 3) so all 4 generated replies land on distinct
      // template indices instead of repeating every other reply — a stride
      // that isn't coprime with the template list length cycles early.
      final commentIndex = (seed + i + 2) % _replyTemplates.length;
      return ForumReply(
        id: '$postId-reply-$i',
        authorName: _replyAuthors[nameIndex],
        body: _replyTemplates[commentIndex],
        createdAt: post.createdAt.add(Duration(hours: 3 + i * 5)),
      );
    });
  }
}
