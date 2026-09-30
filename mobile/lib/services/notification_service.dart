import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService extends ChangeNotifier {
  NotificationService(this._api);

  final ApiService _api;
  static const _readKey = 'read_notification_ids';

  List<AppNotificationModel> _notifications = [];
  Set<String> _readIds = {};
  bool _loading = false;
  Timer? _pollTimer;

  List<AppNotificationModel> get notifications => _notifications;
  bool get loading => _loading;

  int get unreadCount =>
      _notifications.where((n) => !_readIds.contains(n.id)).length;

  AppNotificationModel? get latestUnread {
    for (final n in _notifications) {
      if (!_readIds.contains(n.id)) return n;
    }
    return null;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _readIds = (prefs.getStringList(_readKey) ?? []).toSet();
    await refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _notifications = await _api.fetchNotifications();
    } catch (_) {
      // Keep cached list on failure
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    if (_readIds.contains(id)) return;
    _readIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readKey, _readIds.toList());
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _readIds.addAll(_notifications.map((n) => n.id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readKey, _readIds.toList());
    notifyListeners();
  }

  bool isRead(String id) => _readIds.contains(id);
}
