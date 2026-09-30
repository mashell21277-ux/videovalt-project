import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../models/live_profile.dart';

import '../services/api_service.dart';

import '../theme/app_theme.dart';

import '../widgets/live_badge.dart';

import '../widgets/profile_avatar.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  Future<List<LiveProfileModel>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _load();
  }

  void _load() {
    setState(() {
      _future = context.read<ApiService>().fetchLiveProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFF120818), Color(0xFF0A0A0F), Color(0xFF0F0F18)],
        ),
      ),

      child: SafeArea(
        bottom: false,

        child: RefreshIndicator(
          color: AppColors.primary,

          onRefresh: () async {
            _load();

            await _future;
          },

          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const LiveBadge(size: LiveBadgeSize.medium),

                          const SizedBox(width: 12),

                          const Text(
                            'Live Now',

                            style: TextStyle(
                              fontSize: 26,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Tap a creator to watch live & chat',

                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),

                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              FutureBuilder<List<LiveProfileModel>>(
                future: _future,

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text('Could not load live profiles'),
                      ),
                    );
                  }

                  final profiles = snapshot.data ?? [];

                  if (profiles.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.sensors_rounded,

                              size: 56,

                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'No live profiles yet',

                              style: TextStyle(
                                fontSize: 18,

                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Create profiles in the admin dashboard',

                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.8,
                                ),

                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),

                    sliver: SliverList.separated(
                      itemCount: profiles.length,

                      separatorBuilder: (_, __) => const SizedBox(height: 14),

                      itemBuilder: (context, index) {
                        return _LiveProfileCard(profile: profiles[index]);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveProfileCard extends StatelessWidget {
  const _LiveProfileCard({required this.profile});

  final LiveProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final isLive = profile.latestVideo?.isLive ?? false;

    final latestTitle = profile.latestVideo?.title;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(22),

        onTap: () => context.push('/live/profile/${profile.id}'),

        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            gradient: LinearGradient(
              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

              colors: isLive
                  ? [
                      const Color(0xFFFF2D55).withValues(alpha: 0.14),

                      AppColors.surface,
                    ]
                  : [
                      AppColors.surface,
                      AppColors.surfaceLight.withValues(alpha: 0.5),
                    ],
            ),

            border: Border.all(
              color: isLive
                  ? const Color(0xFFFF2D55).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                ProfileAvatar.fromProfile(
                  profile,

                  size: 64,

                  showLiveRing: isLive,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.name,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontWeight: FontWeight.w800,

                                fontSize: 17,

                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          if (isLive) ...[
                            const SizedBox(width: 8),

                            const LiveBadge(size: LiveBadgeSize.small),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '@${profile.handle}',

                        style: const TextStyle(
                          color: AppColors.textSecondary,

                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isLive
                            ? (latestTitle ?? 'Streaming now')
                            : profile.bio?.isNotEmpty == true
                            ? profile.bio!
                            : '${profile.videoCount} videos · ${profile.messageCount} messages',

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          color: isLive
                              ? AppColors.textPrimary.withValues(alpha: 0.9)
                              : AppColors.textSecondary,

                          fontSize: 13,

                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 40,

                  height: 40,

                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFFFF2D55).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Icon(
                    Icons.chevron_right_rounded,

                    color: isLive
                        ? const Color(0xFFFF6B8A)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
