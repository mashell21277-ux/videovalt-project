import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/live_profile.dart';
import '../models/video.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
    this.showLiveRing = false,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final bool showLiveRing;

  factory ProfileAvatar.fromProfile(
    LiveProfileModel profile, {
    double size = 48,
    bool showLiveRing = false,
  }) {
    return ProfileAvatar(
      name: profile.name,
      avatarUrl: profile.avatarUrl,
      size: size,
      showLiveRing: showLiveRing,
    );
  }

  factory ProfileAvatar.fromVideoProfile(
    VideoProfileInfo profile, {
    double size = 48,
    bool showLiveRing = false,
  }) {
    return ProfileAvatar(
      name: profile.name,
      avatarUrl: profile.avatarUrl,
      size: size,
      showLiveRing: showLiveRing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget avatar;
    final url = AppConfig.mediaUrl(avatarUrl);
    if (url.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(initial),
        ),
      );
    } else {
      avatar = _fallback(initial);
    }

    if (!showLiveRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D55).withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0F),
          shape: BoxShape.circle,
        ),
        child: avatar,
      ),
    );
  }

  Widget _fallback(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
