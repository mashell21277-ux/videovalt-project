class AppConfig {
  static const String baseUrl =
      'https://rahazetu-001-site1.itempurl.com';

  static String videoUrl(String filename) =>
      '$baseUrl/uploads/$filename';

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }
}
