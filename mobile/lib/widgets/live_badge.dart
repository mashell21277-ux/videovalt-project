import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum LiveBadgeSize { small, medium, large }

class LiveBadge extends StatefulWidget {
  const LiveBadge({
    super.key,
    this.size = LiveBadgeSize.medium,
    this.pulse = true,
  });

  final LiveBadgeSize size;
  final bool pulse;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 1, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (hPad, vPad, dotSize, fontSize) = switch (widget.size) {
      LiveBadgeSize.small => (8.0, 4.0, 6.0, 10.0),
      LiveBadgeSize.medium => (10.0, 6.0, 8.0, 11.0),
      LiveBadgeSize.large => (14.0, 8.0, 10.0, 13.0),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF1744)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D55).withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pulse)
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            Container(
              width: dotSize,
              height: dotSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(width: dotSize * 0.6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows LIVE badge while video is playing; hides when video ends.
class PlaybackLiveOverlay extends StatefulWidget {
  const PlaybackLiveOverlay({
    super.key,
    required this.controller,
    required this.isLive,
    this.top = 16,
    this.left = 16,
  });

  final VideoPlayerController? controller;
  final bool isLive;
  final double top;
  final double left;

  @override
  State<PlaybackLiveOverlay> createState() => _PlaybackLiveOverlayState();
}

class _PlaybackLiveOverlayState extends State<PlaybackLiveOverlay> {
  bool _showLive = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTick);
    _onTick();
  }

  @override
  void didUpdateWidget(PlaybackLiveOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTick);
      widget.controller?.addListener(_onTick);
      _onTick();
    }
  }

  void _onTick() {
    final c = widget.controller;
    if (!widget.isLive || c == null || !c.value.isInitialized) {
      if (_showLive) setState(() => _showLive = false);
      return;
    }

    final pos = c.value.position;
    final dur = c.value.duration;
    final ended = dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 200;
    final started = pos.inMilliseconds > 300;
    final visible = !ended && (c.value.isPlaying || started);

    if (visible != _showLive) {
      setState(() => _showLive = visible);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLive) return const SizedBox.shrink();

    return Positioned(
      top: widget.top,
      left: widget.left,
      child: const LiveBadge(size: LiveBadgeSize.large),
    );
  }
}
