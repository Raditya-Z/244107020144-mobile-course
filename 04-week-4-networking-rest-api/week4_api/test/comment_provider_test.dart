import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/api_client.dart';
import 'package:week4_api/data/comment_provider.dart';

void main() {
  final cases = <(DioExceptionType, int?, String)>[
    (
      DioExceptionType.connectionTimeout,
      null,
      'Koneksi timeout. Periksa internet Anda lalu coba lagi.',
    ),
    (
      DioExceptionType.sendTimeout,
      null,
      'Koneksi timeout. Periksa internet Anda lalu coba lagi.',
    ),
    (
      DioExceptionType.receiveTimeout,
      null,
      'Koneksi timeout. Periksa internet Anda lalu coba lagi.',
    ),
    (
      DioExceptionType.connectionError,
      null,
      'Tidak dapat terhubung ke server. Periksa internet Anda.',
    ),
    (DioExceptionType.badResponse, 404, 'Komentar tidak ditemukan (404).'),
    (
      DioExceptionType.badResponse,
      500,
      'Server sedang bermasalah (500). Coba lagi nanti.',
    ),
  ];

  for (final (type, status, message) in cases) {
    test(
      'Error $type/$status menjadi AsyncError, lalu refresh berhasil',
      () async {
        final dio = createDio();
        dio.interceptors.clear();
        var shouldFail = true;
        var calls = 0;
        // Interceptor mensimulasikan respons tanpa request internet.
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls++;
              expect(options.path, '/comments');
              expect(options.queryParameters['postId'], 7);
              expect(options.baseUrl, 'https://jsonplaceholder.typicode.com');
              expect(options.connectTimeout, const Duration(seconds: 10));
              expect(options.sendTimeout, const Duration(seconds: 10));
              expect(options.receiveTimeout, const Duration(seconds: 10));
              if (shouldFail) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: type,
                    response: status == null
                        ? null
                        : Response(requestOptions: options, statusCode: status),
                  ),
                );
              } else {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: [
                      {
                        'postId': 7,
                        'id': 1,
                        'name': 'Komentar',
                        'email': 'a@example.com',
                        'body': 'Isi',
                      },
                    ],
                  ),
                );
              }
            },
          ),
        );
        final container = ProviderContainer(
          overrides: [dioProvider.overrideWithValue(dio)],
        );
        addTearDown(() {
          container.dispose();
          dio.close();
        });
        final provider = commentsProvider(7);
        final states = <AsyncValue<dynamic>>[];
        container.listen(
          provider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );

        await expectLater(
          container.read(provider.future),
          throwsA(isA<DioException>()),
        );
        final failed = container.read(provider);
        expect(failed.hasError, isTrue);
        expect(commentErrorMessage(failed.error!), message);
        expect(calls, 1);

        shouldFail = false;
        await container.read(provider.notifier).refresh();
        expect(states.any((state) => state.isLoading), isTrue);
        final comments = container.read(provider).requireValue;
        expect(comments.single.postId, 7);
        expect(comments.single.body, 'Isi');
        expect(calls, 2);
      },
    );
  }

  test('Provider komentar memakai client bersama', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      identical(
        container.read(dioProvider),
        container.read(commentDioProvider),
      ),
      isTrue,
    );
  });
}
