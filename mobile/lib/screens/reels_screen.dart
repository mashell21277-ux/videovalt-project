import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import '../config/constants.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/download_button.dart';
import '../widgets/live_badge.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  List<VideoModel> _reels = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final reels = await api.fetchVideos(
        type: VideoType.reel,
        excludeLive: true,
      );
      if (mounted) {
        setState(() {
          _reels = reels;
          _loading = false;
        });
        if (reels.isNotEmpty) _initController(0);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Cannot connect to server at ${AppConfig.baseUrl}';
        });
      }
    }
  }

  Future<void> _initController(int index) async {
    if (index < 0 || index >= _reels.length) return;

    if (_controllers.containsKey(index)) {
      await _controllers[index]!.play();
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_reels[index].playbackUrl),
    );
    _controllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      if (index == _currentIndex) await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.lightImpact();

    for (final entry in _controllers.entries) {
      if (entry.key == index) {
        entry.value.play();
      } else {
        entry.value.pause();
      }
    }
    _initController(index);
    if (index + 1 < _reels.length) _initController(index + 1);
  }

  void _togglePlayPause(int index) {
    final controller = _controllers[index];
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _ReelsLoadingState();
    }

    if (_error != null) {
      return _ReelsErrorState(message: _error!, onRetry: _loadReels);
    }

    if (_reels.isEmpty) {
      return _ReelsEmptyState(onRetry: _loadReels);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _ReelPage(
                  reel: _reels[index],
                  controller: _controllers[index],
                  index: index,
                  total: _reels.length,
                  onTap: () => _togglePlayPause(index),
                );
              },
            ),
            _ReelsTopBar(onRefresh: _loadReels),
            Positioned(
              right: 8,
              top: MediaQuery.sizeOf(context).height * 0.35,
              child: _ScrollHint(total: _reels.length, current: _currentIndex),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.reel,
    required this.controller,
    required this.index,
    required this.total,
    required this.onTap,
  });

  final VideoModel reel;
  final VideoPlayerController? controller;
  final int index;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isReady = controller != null && controller!.value.isInitialized;
    final isPaused = isReady && !controller!.value.isPlaying;
    final categoryColors = reel.category.gradient;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller!.value.size.height,
                child: VideoPlayer(controller!),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1a1a2e), Color(0xFF0a0a0f)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),

          PlaybackLiveOverlay(
            controller: controller,
            isLive: reel.isLive,
            top: 72,
            left: 16,
          ),

          if (reel.isLive && (isPaused || !isReady))
            const Positioned(
              top: 72,
              left: 16,
              child: LiveBadge(size: LiveBadgeSize.medium),
            ),

          // Top vignette
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x99000000), Colors.transparent],
              ),
            ),
          ),

          // Bottom vignette
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          if (isPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),

          // Right action rail
          Positioned(
            right: 12,
            bottom: 130,
            child: Column(
              children: [
                _ActionBubble(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Save',
                  child: DownloadButton(
                    video: reel,
                    compact: true,
                    overlay: true,
                  ),
                ),
                const SizedBox(height: 20),
                _ActionBubble(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 16,
            right: 72,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: categoryColors),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reel.category.emoji} ${reel.category.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reel.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (reel.description != null && reel.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    reel.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.swipe_up_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${index + 1} of $total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress bar
          if (isReady)
            Positioned(
              left: 0,
              right: 0,
              bottom: 88,
              child: VideoProgressIndicator(
                controller!,
                allowScrubbing: false,
                colors: VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({
    required this.icon,
    required this.label,
    this.onTap,
    this.child,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: child ??
              IconButton(
                onPressed: onTap,
                icon: Icon(icon, color: Colors.white, size: 22),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ReelsTopBar extends StatelessWidget {
  const _ReelsTopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'VideoVault',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.accent.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'For You',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(total.clamp(0, 8), (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 3),
          width: 3,
          height: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _ReelsLoadingState extends StatelessWidget {
  const _ReelsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14141C), Color(0xFF0A0A0F)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading reels...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelsEmptyState extends StatelessWidget {
  const _ReelsEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF0a0a0f)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'No reels yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Post as type "Reel" in admin to show here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReelsErrorState extends StatelessWidget {
  const _ReelsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Cannot load videos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phone and PC must be on same Wi‑Fi.\nCheck app_config.dart server IP.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
