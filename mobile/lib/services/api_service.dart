import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../config/app_config.dart';
import '../config/constants.dart';
import '../models/app_notification.dart';
import '../models/live_profile.dart';
import '../models/video.dart';
import 'auth_service.dart';

class ApiService {
  ApiService(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authService.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final AuthService _authService;
  late final Dio _dio;

  Future<List<VideoModel>> fetchVideos({
    VideoCategory? category,
    VideoType? type,
    bool? liveOnly,
    bool? excludeLive,
  }) async {
    final query = <String, dynamic>{};
    if (category != null) query['category'] = category.apiValue;
    if (type != null) query['type'] = type.apiValue;
    if (liveOnly == true) query['live'] = 'true';
    if (excludeLive == true) query['live'] = 'false';

    final response = await _dio.get<List<dynamic>>(
      '/api/videos',
      queryParameters: query,
    );

    return (response.data ?? [])
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VideoModel> uploadVideo({
    required PlatformFile file,
    required String title,
    String? description,
    required VideoCategory category,
    required VideoType type,
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description ?? '',
      'category': category.apiValue,
      'type': type.apiValue,
      'file': await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/videos',
      data: formData,
      onSendProgress: onProgress,
    );

    return VideoModel.fromJson(response.data!);
  }

  Future<void> deleteVideo(String id) async {
    await _dio.delete('/api/videos/$id');
  }

  Future<List<LiveProfileModel>> fetchLiveProfiles() async {
    final response = await _dio.get<List<dynamic>>('/api/live-profiles');
    return (response.data ?? [])
        .map((e) => LiveProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LiveProfileDetail> fetchLiveProfileDetail(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/live-profiles/$id');
    final data = response.data!;
    final profile = LiveProfileModel.fromJson(data);
    final videos = (data['videos'] as List<dynamic>)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final messages = (data['messages'] as List<dynamic>)
        .map((e) => ProfileMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return LiveProfileDetail(
      profile: profile,
      videos: videos,
      messages: messages,
    );
  }

  Future<List<AppNotificationModel>> fetchNotifications() async {
    final response = await _dio.get<List<dynamic>>('/api/notifications');
    return (response.data ?? [])
        .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProfileMessage> postProfileMessage({
    required String profileId,
    required String authorName,
    required String content,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/live-profiles/$profileId/messages',
      data: {'authorName': authorName, 'content': content},
    );
    return ProfileMessage.fromJson(response.data!);
  }
}
