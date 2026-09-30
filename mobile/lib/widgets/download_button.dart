import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.video,
    this.compact = false,
    this.overlay = false,
  });

  final VideoModel video;
  final bool compact;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offline, _) {
        final isSaved = offline.isOffline(video.id);
        final isDownloading = offline.downloading.contains(video.id);

        Future<void> onTap() async {
          if (isSaved) {
            await offline.remove(video.id);
          } else {
            await offline.download(video);
            if (context.mounted && !offline.isOffline(video.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download failed')),
              );
            }
          }
        }

        final iconColor = overlay
            ? Colors.white
            : isSaved
                ? Colors.greenAccent
                : AppColors.textSecondary;

        if (compact) {
          return IconButton(
            onPressed: isDownloading ? null : onTap,
            icon: isDownloading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: overlay ? Colors.white : null,
                    ),
                  )
                : Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                    color: isSaved && overlay ? Colors.greenAccent : iconColor,
                  ),
          );
        }

        return FilledButton.icon(
          onPressed: isDownloading ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: isSaved
                ? Colors.green.withValues(alpha: 0.2)
                : AppColors.surfaceLight,
            foregroundColor: isSaved ? Colors.greenAccent : AppColors.textPrimary,
          ),
          icon: isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isSaved ? Icons.check : Icons.download_outlined),
          label: Text(
            isDownloading
                ? 'Saving...'
                : isSaved
                    ? 'Saved'
                    : 'Download',
          ),
        );
      },
    );
  }
}
