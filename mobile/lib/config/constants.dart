import 'package:flutter/material.dart';

enum VideoCategory { entertainment, education, music, sports }

enum VideoType { video, reel }

extension VideoCategoryX on VideoCategory {
  String get apiValue => name.toUpperCase();

  String get label {
    switch (this) {
      case VideoCategory.entertainment:
        return 'Entertainment';
      case VideoCategory.education:
        return 'Education';
      case VideoCategory.music:
        return 'Music';
      case VideoCategory.sports:
        return 'Sports';
    }
  }

  String get emoji {
    switch (this) {
      case VideoCategory.entertainment:
        return '🎬';
      case VideoCategory.education:
        return '📚';
      case VideoCategory.music:
        return '🎵';
      case VideoCategory.sports:
        return '⚽';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case VideoCategory.entertainment:
        return [const Color(0xFF8B5CF6), const Color(0xFF9333EA)];
      case VideoCategory.education:
        return [const Color(0xFF3B82F6), const Color(0xFF0891B2)];
      case VideoCategory.music:
        return [const Color(0xFFEC4899), const Color(0xFFE11D48)];
      case VideoCategory.sports:
        return [const Color(0xFF10B981), const Color(0xFF16A34A)];
    }
  }

  static VideoCategory fromApi(String value) {
    return VideoCategory.values.firstWhere(
      (c) => c.apiValue == value.toUpperCase(),
      orElse: () => VideoCategory.entertainment,
    );
  }
}

extension VideoTypeX on VideoType {
  String get apiValue => name.toUpperCase();

  static VideoType fromApi(String value) {
    return VideoType.values.firstWhere(
      (t) => t.apiValue == value.toUpperCase(),
      orElse: () => VideoType.video,
    );
  }
}

const categories = VideoCategory.values;
