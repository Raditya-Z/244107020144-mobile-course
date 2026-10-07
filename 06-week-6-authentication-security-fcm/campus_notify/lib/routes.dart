class AppRoutes {
  static const home = '/';
  static const login = '/login';

  static const announcementPattern = '/pengumuman/:id';

  static String announcement(String id) {
    return '/pengumuman/$id';
  }
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';

  return route.startsWith('/')
      ? route
      : '/$route';
}