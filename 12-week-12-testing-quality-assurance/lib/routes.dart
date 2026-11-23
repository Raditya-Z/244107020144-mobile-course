export 'core/format.dart' show routeFromMessage;

class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const notes = '/notes';
  static const ai = '/ai';
  static const aiSettings = '/ai/pengaturan';

  static const announcementPattern = '/pengumuman/:id';

  static String announcement(String id) {
    return '/pengumuman/$id';
  }
}
