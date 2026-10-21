import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

Dio buildDio({
  required TokenStore tokenStore,
  required AuthRepository authRepository,
  String baseUrl = 'https://jsonplaceholder.typicode.com',
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokenStore.readAccess();

        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }

        handler.next(options);
      },

      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refresh = await tokenStore.readRefresh();

          if (refresh == null) {
            return handler.next(error);
          }

          try {
            final newAccess = await authRepository.refresh(refresh);

            await tokenStore.save(access: newAccess, refresh: refresh);

            final request = error.requestOptions;

            request.headers['Authorization'] = 'Bearer $newAccess';

            final response = await dio.fetch(request);

            return handler.resolve(response);
          } catch (_) {
            await tokenStore.clear();
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}
