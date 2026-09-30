import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/videos')) return 1;
    if (location.startsWith('/live')) return 2;
    if (location.startsWith('/offline')) return 3;
    return 0;
  }

  bool _isReelsHome(BuildContext context) {
    return GoRouterState.of(context).uri.path == '/';
  }

  bool _hideBell(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return path == '/notifications';
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isReels = _isReelsHome(context);
    final showBell = !_hideBell(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          child,
          if (showBell)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Consumer<NotificationService>(
                builder: (context, notifications, _) {
                  final unread = notifications.unreadCount;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/notifications'),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isReels
                              ? Colors.black.withValues(alpha: 0.45)
                              : AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread'),
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            unread > 0
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, isReels ? 20 : 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isReels
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: NavigationBar(
                height: 64,
                selectedIndex: index,
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.primary.withValues(alpha: 0.25),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                surfaceTintColor: Colors.transparent,
                onDestinationSelected: (i) {
                  switch (i) {
                    case 0:
                      context.go('/');
                    case 1:
                      context.go('/videos');
                    case 2:
                      context.go('/live');
                    case 3:
                      context.go('/offline');
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.play_circle_outline),
                    selectedIcon: Icon(Icons.play_circle_fill),
                    label: 'Reels',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Videos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sensors_outlined),
                    selectedIcon: Icon(Icons.sensors),
                    label: 'Live',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.download_outlined),
                    selectedIcon: Icon(Icons.download_done_rounded),
                    label: 'Offline',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
