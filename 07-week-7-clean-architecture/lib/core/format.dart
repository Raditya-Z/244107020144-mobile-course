
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day/$month/$year';
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';

  return route.startsWith('/')
      ? route
      : '/$route';
}
