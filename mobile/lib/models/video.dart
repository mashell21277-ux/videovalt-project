import '../config/app_config.dart';
import '../config/constants.dart';

class VideoProfileInfo {
  const VideoProfileInfo({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;

  factory VideoProfileInfo.fromJson(Map<String, dynamic> json) {
    return VideoProfileInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class VideoModel {
  const VideoModel({
    required this.id,
    required this.title,
    this.description,
    this.filename,
    this.sourceUrl,
    required this.category,
    required this.type,
    this.fileSize,
    this.isLive = false,
    this.profileId,
    this.profile,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? filename;
  final String? sourceUrl;
  final VideoCategory category;
  final VideoType type;
  final int? fileSize;
  final bool isLive;
  final String? profileId;
  final VideoProfileInfo? profile;
  final DateTime createdAt;

  /// Direct link (Dropbox, etc.) or local server upload path.
  String get playbackUrl {
    if (sourceUrl != null && sourceUrl!.isNotEmpty) return sourceUrl!;
    if (filename != null && filename!.isNotEmpty) {
      return AppConfig.videoUrl(filename!);
    }
    return '';
  }

  bool get isExternal => sourceUrl != null && sourceUrl!.isNotEmpty;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      filename: json['filename'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      category: VideoCategoryX.fromApi(json['category'] as String),
      type: VideoTypeX.fromApi(json['type'] as String),
      fileSize: json['fileSize'] as int?,
      isLive: json['isLive'] as bool? ?? false,
      profileId: json['profileId'] as String?,
      profile: json['profile'] != null
          ? VideoProfileInfo.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get formattedSize {
    final bytes = fileSize;
    if (bytes == null) return isExternal ? 'Linked' : 'Unknown size';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(1)} ${units[index]}';
  }
}
