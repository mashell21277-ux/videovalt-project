import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/live_profile.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_badge.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/video_player_dialog.dart';

enum _ProfileSection { videos, messages }

class LiveProfileScreen extends StatefulWidget {
  const LiveProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<LiveProfileScreen> createState() => _LiveProfileScreenState();
}

class _LiveProfileScreenState extends State<LiveProfileScreen> {
  Future<LiveProfileDetail>? _future;
  final _messageController = TextEditingController();
  final _nameController = TextEditingController(text: 'Guest');
  final _chatScrollController = ScrollController();
  bool _sending = false;
  _ProfileSection _section = _ProfileSection.videos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<ApiService>().fetchLiveProfileDetail(widget.profileId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = context.read<ApiService>().fetchLiveProfileDetail(widget.profileId);
    });
    await _future;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await context.read<ApiService>().postProfileMessage(
            profileId: widget.profileId,
            authorName: _nameController.text.trim().isEmpty
                ? 'Guest'
                : _nameController.text.trim(),
            content: text,
          );
      _messageController.clear();
      await _refresh();
      if (_chatScrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _playVideo(VideoModel video) {
    showDialog<void>(
      context: context,
      builder: (_) => VideoPlayerDialog(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<LiveProfileDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load profile'),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
                ],
              ),
            );
          }

          final detail = snapshot.data!;
          final profile = detail.profile;
          final liveVideo = detail.videos.where((v) => v.isLive).firstOrNull;
          final allVideos = detail.videos;

          return Column(
            children: [
              _ProfileHero(profile: profile, isLive: liveVideo != null),
              _SectionPicker(
                section: _section,
                videoCount: allVideos.length,
                messageCount: detail.messages.length,
                onVideos: () => setState(() => _section = _ProfileSection.videos),
                onMessages: () => setState(() => _section = _ProfileSection.messages),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _section == _ProfileSection.videos
                      ? _VideosPanel(
                          key: const ValueKey('videos'),
                          liveVideo: liveVideo,
                          videos: allVideos,
                          onPlay: _playVideo,
                          onRefresh: _refresh,
                        )
                      : _MessagesPanel(
                          key: const ValueKey('messages'),
                          messages: detail.messages,
                          nameController: _nameController,
                          messageController: _messageController,
                          scrollController: _chatScrollController,
                          sending: _sending,
                          onSend: _sendMessage,
                          onRefresh: _refresh,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.isLive});

  final LiveProfileModel profile;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1025), Color(0xFF0F0F18), Color(0xFF120818)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  if (isLive) ...[
                    const Spacer(),
                    const LiveBadge(size: LiveBadgeSize.small),
                  ],
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileAvatar.fromProfile(
                    profile,
                    size: 72,
                    showLiveRing: isLive,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${profile.handle}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            profile.bio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.95),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({
    required this.section,
    required this.videoCount,
    required this.messageCount,
    required this.onVideos,
    required this.onMessages,
  });

  final _ProfileSection section;
  final int videoCount;
  final int messageCount;
  final VoidCallback onVideos;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _SectionTile(
              label: 'Videos',
              icon: Icons.play_circle_rounded,
              count: videoCount,
              accent: const [Color(0xFFFF2D55), Color(0xFFFF6B35)],
              selected: section == _ProfileSection.videos,
              onTap: onVideos,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SectionTile(
              label: 'Messages',
              icon: Icons.chat_bubble_rounded,
              count: messageCount,
              accent: const [Color(0xFF0EA5E9), Color(0xFF6366F1)],
              selected: section == _ProfileSection.messages,
              onTap: onMessages,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final List<Color> accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.first.withValues(alpha: 0.22),
                      accent.last.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: selected ? null : AppColors.surface,
            border: Border.all(
              color: selected
                  ? accent.first.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.06),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.first.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: accent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$count ${label == 'Videos' ? 'streams' : 'msgs'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? accent.first.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent.first, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideosPanel extends StatelessWidget {
  const _VideosPanel({
    super.key,
    required this.liveVideo,
    required this.videos,
    required this.onPlay,
    required this.onRefresh,
  });

  final VideoModel? liveVideo;
  final List<VideoModel> videos;
  final void Function(VideoModel) onPlay;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final pastVideos = videos.where((v) => !v.isLive).toList();

    if (liveVideo == null && pastVideos.isEmpty) {
      return _EmptySection(
        icon: Icons.videocam_off_outlined,
        title: 'No videos yet',
        subtitle: 'Streams from this profile will appear here',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          if (liveVideo != null) ...[
            _FeaturedLiveVideo(video: liveVideo!, onTap: () => onPlay(liveVideo!)),
            const SizedBox(height: 20),
          ],
          if (pastVideos.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Past streams',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pastVideos.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pastVideos.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PastVideoTile(video: v, onTap: () => onPlay(v)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessagesPanel extends StatelessWidget {
  const _MessagesPanel({
    super.key,
    required this.messages,
    required this.nameController,
    required this.messageController,
    required this.scrollController,
    required this.sending,
    required this.onSend,
    required this.onRefresh,
  });

  final List<ProfileMessage> messages;
  final TextEditingController nameController;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final bool sending;
  final VoidCallback onSend;
  final Future<void> Function() onRefresh;

  String get _currentName =>
      nameController.text.trim().isEmpty ? 'Guest' : nameController.text.trim();

  bool _isMine(ProfileMessage message) =>
      message.authorName.trim().toLowerCase() == _currentName.toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B141A),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _ChatWallpaper()),
                RefreshIndicator(
                  color: const Color(0xFF00A884),
                  onRefresh: onRefresh,
                  child: messages.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            _EmptySection(
                              icon: Icons.forum_outlined,
                              title: 'No messages yet',
                              subtitle: 'Send a message to start the chat',
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _WhatsAppBubble(
                                message: messages[index],
                                isMine: _isMine(messages[index]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          _WhatsAppInputBar(
            nameController: nameController,
            messageController: messageController,
            sending: sending,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppInputBar extends StatefulWidget {
  const _WhatsAppInputBar({
    required this.nameController,
    required this.messageController,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController nameController;
  final TextEditingController messageController;
  final bool sending;
  final VoidCallback onSend;

  @override
  State<_WhatsAppInputBar> createState() => _WhatsAppInputBarState();
}

class _WhatsAppInputBarState extends State<_WhatsAppInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
    _hasText = widget.messageController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.messageController.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  void _showNameSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your display name',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Guest',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: const Color(0xFF2A3942),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(6, 8, 6, 6 + bottom),
      color: const Color(0xFF1F2C34),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _showNameSheet,
            icon: const Icon(Icons.person_outline, color: Color(0xFF8696A0)),
            tooltip: 'Your name',
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.messageController,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (_hasText && !widget.sending) widget.onSend();
                },
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: const Color(0xFF00A884),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.sending || !_hasText ? null : widget.onSend,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: widget.sending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _hasText ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatWallpaper extends StatelessWidget {
  const _ChatWallpaper();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChatWallpaperPainter(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0B141A).withValues(alpha: 0.92),
              const Color(0xFF0B141A).withValues(alpha: 0.97),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatWallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const step = 48.0;
    for (var x = 0.0; x < size.width + step; x += step) {
      for (var y = 0.0; y < size.height + step; y += step) {
        final cx = x + step / 2;
        final cy = y + step / 2;
        canvas.drawCircle(Offset(cx, cy), 3, paint);
        canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), paint);
        canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _formatChatTime(DateTime dt) {
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class _WhatsAppBubble extends StatelessWidget {
  const _WhatsAppBubble({required this.message, required this.isMine});

  final ProfileMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final bubbleColor = isMine ? const Color(0xFF005C4B) : const Color(0xFF1F2C34);
    final radius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(2),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(10),
          );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: EdgeInsets.only(
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.authorName,
                    style: const TextStyle(
                      color: Color(0xFF53BDEB),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                message.content,
                style: const TextStyle(
                  color: Color(0xFFE9EDEF),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatChatTime(message.createdAt.toLocal()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedLiveVideo extends StatelessWidget {
  const _FeaturedLiveVideo({required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFF2D55).withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF2D55).withValues(alpha: 0.12),
                AppColors.surface,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: Icon(Icons.play_circle_filled, size: 64, color: Colors.white38),
                        ),
                      ),
                    ),
                    const Positioned(top: 12, left: 12, child: LiveBadge(size: LiveBadgeSize.medium)),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Now streaming — tap to watch',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF1744)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Watch',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastVideoTile extends StatelessWidget {
  const _PastVideoTile({required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.formattedSize,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

