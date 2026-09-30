import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../config/constants.dart';
import '../models/video.dart';
import '../theme/app_theme.dart';
import 'download_button.dart';
import 'live_badge.dart';

class VideoPlayerDialog extends StatefulWidget {
  const VideoPlayerDialog({
    super.key,
    required this.video,
    this.localPath,
    this.webBytes,
  });

  final VideoModel video;
  final String? localPath;
  final List<int>? webBytes;

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.webBytes != null) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.dataFromBytes(widget.webBytes!, mimeType: 'video/mp4'),
        );
      } else if (widget.localPath != null && !kIsWeb) {
        _videoController = VideoPlayerController.file(File(widget.localPath!));
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.playbackUrl),
        );
      }

      await _videoController!.initialize();
      _videoController!.addListener(_onVideoUpdate);
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load video';
        });
      }
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = widget.localPath != null || widget.webBytes != null;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Chewie(controller: _chewieController!),
                            PlaybackLiveOverlay(
                              controller: _videoController,
                              isLive: widget.video.isLive,
                              top: 12,
                              left: 12,
                            ),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.video.isLive) ...[
                              const LiveBadge(
                                size: LiveBadgeSize.small,
                                pulse: false,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                widget.video.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.video.category.emoji} ${widget.video.category.label}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!isOffline) DownloadButton(video: widget.video),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
