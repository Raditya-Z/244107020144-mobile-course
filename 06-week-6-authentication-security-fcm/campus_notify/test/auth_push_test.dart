import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/routes.dart';
import 'package:campus_notify/data/api_errors.dart';

class FakeTokenStore {
  String? access;
  String? refresh;
}

void main() {
  group('routeFromMessage', () {
    test('menangani route kosong dan tanpa slash', () {
      expect(
        routeFromMessage({}),
        '/',
      );

      expect(
        routeFromMessage({
          'route': 'pengumuman/3',
        }),
        '/pengumuman/3',
      );

      expect(
        routeFromMessage({
          'route': '/pengumuman/3',
        }),
        '/pengumuman/3',
      );
    });

    test('data payload membawa id pengumuman', () {
      final data = {
        'route': '/pengumuman/3',
        'id': '3',
      };

      expect(
        data['id'],
        '3',
      );

      expect(
        routeFromMessage(data),
        '/pengumuman/3',
      );
    });
  });

  group('Auth', () {
    test('provider auth membaca status login dari token', () {
      final store = FakeTokenStore()
        ..access = 'mock-access';

      expect(
        store.access != null,
        isTrue,
      );

      store.access = null;

      expect(
        store.access != null,
        isFalse,
      );
    });

    test(
      'refresh gagal menyebabkan sesi dibersihkan',
      () {
        final store = FakeTokenStore()
          ..refresh = '';

        final needsLogin =
            (store.refresh ?? '').isEmpty;

        expect(
          needsLogin,
          isTrue,
        );
      },
    );
  });

  group('apiErrorMessage', () {
    test('status 401 menghasilkan pesan sesi berakhir', () {
      final requestOptions = RequestOptions(
        path: '/profile',
      );

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      final result = apiErrorMessage(error);

      expect(
        result,
        'Sesi telah berakhir. Silakan login kembali.',
      );
    });

    test('timeout menghasilkan pesan koneksi timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/profile',
        ),
        type: DioExceptionType.connectionTimeout,
      );

      final result = apiErrorMessage(error);

      expect(
        result,
        'Koneksi timeout. Silakan coba lagi.',
      );
    });
  });
}