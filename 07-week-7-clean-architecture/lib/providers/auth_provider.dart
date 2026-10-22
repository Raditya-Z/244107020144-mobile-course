import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/services/token_store.dart';
import '../features/auth/domain/usecases/login_usecase.dart';

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(
    ref.watch(authRepositoryProvider),
  ),
);

final authProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final access =
        await ref.read(tokenStoreProvider).readAccess();

    return access != null;
  }

  Future<void> login(
    String email,
    String password,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final session =
          await ref.read(loginUseCaseProvider)(
                email: email,
                password: password,
              );

      await ref.read(tokenStoreProvider).save(
            access: session.access,
            refresh: session.refresh,
          );

      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}