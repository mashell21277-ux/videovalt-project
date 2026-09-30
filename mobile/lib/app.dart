import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/live_profile_screen.dart';
import 'screens/live_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/reels_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/offline_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

class VideoVaultApp extends StatefulWidget {
  const VideoVaultApp({super.key});

  @override
  State<VideoVaultApp> createState() => _VideoVaultAppState();
}

class _VideoVaultAppState extends State<VideoVaultApp> {
  late final AuthService _authService;
  late final ApiService _apiService;
  late final OfflineService _offlineService;
  late final NotificationService _notificationService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService(_authService);
    _offlineService = OfflineService();
    _notificationService = NotificationService(_apiService);

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const ReelsScreen(),
            ),
            GoRoute(
              path: '/videos',
              builder: (_, __) => const HomeScreen(),
            ),
            GoRoute(
              path: '/live',
              builder: (_, __) => const LiveScreen(),
            ),
            GoRoute(
              path: '/live/profile/:id',
              builder: (context, state) => LiveProfileScreen(
                profileId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/offline',
              builder: (_, __) => const OfflineScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    );

    _authService.init();
    _offlineService.init();
    _notificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        Provider.value(value: _apiService),
        ChangeNotifierProvider.value(value: _offlineService),
        ChangeNotifierProvider.value(value: _notificationService),
      ],
      child: MaterialApp.router(
        title: 'VideoVault',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
