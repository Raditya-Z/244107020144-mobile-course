
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/format.dart';

void main() {
  group('formatDate', () {
    test('memformat tanggal menjadi dd/MM/yyyy', () {
      expect(
        formatDate(DateTime(2026, 9, 7)),
        '07/09/2026',
      );
    });
  });

  group('routeFromMessage', () {
    test('menggunakan route default jika kosong', () {
      expect(routeFromMessage({}), '/');
    });

    test('menambahkan slash jika belum ada', () {
      expect(
        routeFromMessage({'route': 'login'}),
        '/login',
      );
    });

    test('mempertahankan slash jika sudah ada', () {
      expect(
        routeFromMessage({'route': '/login'}),
        '/login',
      );
    });
  });
}
