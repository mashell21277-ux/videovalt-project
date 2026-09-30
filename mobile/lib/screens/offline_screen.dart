import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/video.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import '../widgets/video_player_dialog.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  VideoModel _toVideoModel(OfflineEntry entry) {
    return VideoModel(
      id: entry.id,
      title: entry.title,
      category: VideoCategoryX.fromApi(entry.category),
      type: VideoTypeX.fromApi(entry.type),
      filename: '',
      createdAt: entry.downloadedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offline, _) {
        final entries = offline.getAll();

        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No offline videos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Download videos from the home page or reels to watch offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entries.length} video${entries.length == 1 ? '' : 's'} saved for offline viewing',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 220,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    final category = VideoCategoryX.fromApi(entry.category);

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          final offline = context.read<OfflineService>();
                          showDialog<void>(
                            context: context,
                            builder: (_) => VideoPlayerDialog(
                              video: _toVideoModel(entry),
                              localPath: entry.isWebBlob ? null : entry.localPath,
                              webBytes: entry.isWebBlob
                                  ? offline.getWebBlob(entry.id)
                                  : null,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: AppColors.surfaceLight),
                                  const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 48,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Offline',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${category.emoji} ${category.label}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: AppColors.textSecondary,
                                    onPressed: () => offline.remove(entry.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: entries.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
