import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../config/constants.dart';
import '../models/video.dart';

class OfflineEntry {
  OfflineEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.localPath,
    required this.downloadedAt,
    this.isWebBlob = false,
  });

  final String id;
  final String title;
  final String category;
  final String type;
  final String localPath;
  final DateTime downloadedAt;
  final bool isWebBlob;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'type': type,
        'localPath': localPath,
        'downloadedAt': downloadedAt.toIso8601String(),
        'isWebBlob': isWebBlob,
      };

  factory OfflineEntry.fromMap(Map<dynamic, dynamic> map) {
    return OfflineEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      type: map['type'] as String,
      localPath: map['localPath'] as String,
      downloadedAt: DateTime.parse(map['downloadedAt'] as String),
      isWebBlob: map['isWebBlob'] as bool? ?? false,
    );
  }
}

class OfflineService extends ChangeNotifier {
  static const _boxName = 'offline_videos';
  static const _blobBoxName = 'offline_blobs';
  Box<Map>? _box;
  Box<List<int>>? _blobBox;
  final Set<String> _downloading = {};

  Set<String> get downloading => Set.unmodifiable(_downloading);

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
    if (kIsWeb) {
      _blobBox = await Hive.openBox<List<int>>(_blobBoxName);
    }
    notifyListeners();
  }

  bool isOffline(String videoId) => _box?.containsKey(videoId) ?? false;

  List<OfflineEntry> getAll() {
    if (_box == null) return [];
    return _box!.values.map((e) => OfflineEntry.fromMap(e)).toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
  }

  OfflineEntry? getEntry(String videoId) {
    final data = _box?.get(videoId);
    if (data == null) return null;
    return OfflineEntry.fromMap(data);
  }

  Future<void> download(VideoModel video) async {
    if (_downloading.contains(video.id) || isOffline(video.id)) return;

    final url = video.playbackUrl;
    if (url.isEmpty) return;

    _downloading.add(video.id);
    notifyListeners();

    try {
      final dio = Dio();
      final storageName =
          video.filename ?? '${video.id}${video.isExternal ? '.mp4' : ''}';

      if (kIsWeb) {
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        await _blobBox?.put(video.id, response.data ?? []);
        await _box?.put(
          video.id,
          OfflineEntry(
            id: video.id,
            title: video.title,
            category: video.category.apiValue,
            type: video.type.apiValue,
            localPath: video.id,
            downloadedAt: DateTime.now(),
            isWebBlob: true,
          ).toMap(),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final offlineDir = Directory('${dir.path}/offline_videos');
        if (!await offlineDir.exists()) {
          await offlineDir.create(recursive: true);
        }

        final localPath = '${offlineDir.path}/$storageName';
        await dio.download(url, localPath);

        await _box?.put(
          video.id,
          OfflineEntry(
            id: video.id,
            title: video.title,
            category: video.category.apiValue,
            type: video.type.apiValue,
            localPath: localPath,
            downloadedAt: DateTime.now(),
          ).toMap(),
        );
      }
    } finally {
      _downloading.remove(video.id);
      notifyListeners();
    }
  }

  Future<void> remove(String videoId) async {
    final entry = getEntry(videoId);
    if (entry != null) {
      if (entry.isWebBlob) {
        await _blobBox?.delete(videoId);
      } else {
        final file = File(entry.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _box?.delete(videoId);
    notifyListeners();
  }

  List<int>? getWebBlob(String videoId) {
    return _blobBox?.get(videoId);
  }
}
