import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  /// Your PC's Wi‑Fi IP — same network as your phone.
  /// Run `ipconfig` on PC and use the 192.168.x.x address.
  static const String serverIp = '192.168.1.187';
  static const int serverPort = 3000;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$serverPort';
    if (Platform.isAndroid) {
      // Physical phone → PC IP. Android emulator → 10.0.2.2
      const useEmulator = false;
      return useEmulator
          ? 'http://10.0.2.2:$serverPort'
          : 'http://$serverIp:$serverPort';
    }
    return 'http://$serverIp:$serverPort';
  }

  static String videoUrl(String filename) => '$baseUrl/uploads/$filename';

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }
}
