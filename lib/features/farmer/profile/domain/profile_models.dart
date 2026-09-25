import 'package:equatable/equatable.dart';

/// One saved delivery / farm address.
class SavedAddress extends Equatable {
  const SavedAddress({
    this.addressId = '',
    required this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    this.landmark = '',
    this.village = '',
    this.taluka = '',
    this.district = '',
    this.state = 'Maharashtra',
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        addressId: json['addressId'] as String,
        label: json['label'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        line1: json['line1'] as String,
        line2: json['line2'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        village: json['village'] as String? ?? '',
        taluka: json['taluka'] as String? ?? '',
        district: json['district'] as String? ?? '',
        state: json['state'] as String? ?? 'Maharashtra',
        pincode: json['pincode'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['isDefault'] as bool? ?? false,
      );

  final String addressId;
  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String landmark;
  final String village;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  bool get hasPin => latitude != null && longitude != null;

  /// The address as a few lines of text, the way it is read on a parcel.
  String get formatted {
    final place = [village, district].where((p) => p.isNotEmpty).join(', ');
    return [line1, line2, if (landmark.isNotEmpty) 'Near $landmark', place, '$state - $pincode'].where((p) => p.isNotEmpty).join('\n');
  }

  Map<String, dynamic> toBody({bool includeDefault = false}) => {
        'label': label,
        'fullName': fullName,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'landmark': landmark,
        'village': village,
        'taluka': taluka,
        'district': district,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        if (includeDefault) 'isDefault': isDefault,
      };

  @override
  List<Object?> get props => [addressId, label, fullName, phone, line1, line2, landmark, village, taluka, district, state, pincode, latitude, longitude, isDefault];
}

/// How to reach the farmer. The login email is fixed; these are for contact.
class ContactInfo extends Equatable {
  const ContactInfo({this.email = '', this.phone = '', this.loginEmail = ''});

  factory ContactInfo.fromJson(Map<String, dynamic> json) =>
      ContactInfo(email: json['email'] as String? ?? '', phone: json['phone'] as String? ?? '', loginEmail: json['loginEmail'] as String? ?? '');

  final String email;
  final String phone;
  final String loginEmail;

  @override
  List<Object?> get props => [email, phone, loginEmail];
}

/// A post the farmer wrote.
class ActivityPost extends Equatable {
  const ActivityPost({required this.postId, required this.title, required this.content, required this.commentCount, required this.likeCount, required this.createdAt});

  factory ActivityPost.fromJson(Map<String, dynamic> json) => ActivityPost(
        postId: json['postId'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        commentCount: (json['commentCount'] as num).toInt(),
        likeCount: (json['likeCount'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String postId;
  final String title;
  final String content;
  final int commentCount;
  final int likeCount;
  final DateTime createdAt;

  @override
  List<Object?> get props => [postId, title, content, commentCount, likeCount, createdAt];
}

/// A reply the farmer wrote, with the post it is under.
class ActivityReply extends Equatable {
  const ActivityReply({required this.commentId, required this.postId, required this.postTitle, required this.content, required this.createdAt});

  factory ActivityReply.fromJson(Map<String, dynamic> json) => ActivityReply(
        commentId: json['commentId'] as String,
        postId: json['postId'] as String,
        postTitle: json['postTitle'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String commentId;
  final String postId;
  final String postTitle;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [commentId, postId, postTitle, content, createdAt];
}

class MyActivity extends Equatable {
  const MyActivity({this.posts = const [], this.replies = const []});

  factory MyActivity.fromJson(Map<String, dynamic> json) => MyActivity(
        posts: (json['posts'] as List).map((e) => ActivityPost.fromJson(e as Map<String, dynamic>)).toList(),
        replies: (json['comments'] as List).map((e) => ActivityReply.fromJson(e as Map<String, dynamic>)).toList(),
      );

  final List<ActivityPost> posts;
  final List<ActivityReply> replies;

  @override
  List<Object?> get props => [posts, replies];
}

/// What the farmer told us once, so schemes can be checked without asking again.
/// Keys match the server's list (`GET /v1/farmer/details`).
class FarmDetails extends Equatable {
  const FarmDetails([this.answers = const {}]);

  factory FarmDetails.fromJson(Map<String, dynamic> json) => FarmDetails(Map<String, dynamic>.from(json['details'] as Map));

  final Map<String, dynamic> answers;

  bool? flag(String key) => answers[key] as bool?;
  String? text(String key) => answers[key] as String?;
  List<String> list(String key) => ((answers[key] as List?) ?? const []).cast<String>();
  bool get isEmpty => answers.isEmpty;

  /// Age in whole years from `dateOfBirth`, or null.
  int? age([DateTime? now]) {
    final dob = DateTime.tryParse(text('dateOfBirth') ?? '');
    if (dob == null) return null;
    final today = now ?? DateTime.now();
    var years = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) years -= 1;
    return years;
  }

  @override
  List<Object?> get props => [answers];
}
