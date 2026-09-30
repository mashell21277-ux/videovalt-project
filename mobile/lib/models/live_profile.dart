import 'video.dart';

class LiveProfileModel {
  const LiveProfileModel({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.latestVideo,
    this.videoCount = 0,
    this.messageCount = 0,
  });

  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final VideoModel? latestVideo;
  final int videoCount;
  final int messageCount;

  factory LiveProfileModel.fromJson(Map<String, dynamic> json) {
    return LiveProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      latestVideo: json['latestVideo'] != null
          ? VideoModel.fromJson(json['latestVideo'] as Map<String, dynamic>)
          : null,
      videoCount: json['videoCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }
}

class LiveProfileDetail {
  const LiveProfileDetail({
    required this.profile,
    required this.videos,
    required this.messages,
  });

  final LiveProfileModel profile;
  final List<VideoModel> videos;
  final List<ProfileMessage> messages;
}

class ProfileMessage {
  const ProfileMessage({
    required this.id,
    required this.profileId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory ProfileMessage.fromJson(Map<String, dynamic> json) {
    return ProfileMessage(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      authorName: json['authorName'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
