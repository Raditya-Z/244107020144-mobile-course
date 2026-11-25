import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:campus_notify/providers/auth_provider.dart';
import 'package:campus_notify/router.dart';

/// Sesi login disimulasikan agar alur yang diuji tidak bergantung pada API
/// autentikasi. Sisanya memakai implementasi nyata: router, halaman, dan
/// repository SQLite di perangkat.
class _LoggedInAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async => true;
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pengguna menambah catatan lalu mencarinya', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_LoggedInAuthNotifier.new)],
        child: const _TestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login berhasil'), findsOneWidget);

    await tester.tap(find.text('Buka Catatan'));
    await tester.pumpAndSettle();

    final title = 'Catatan uji ${DateTime.now().millisecondsSinceEpoch}';

    await tester.tap(find.byKey(const Key('add-note-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('note-title-field')), title);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('note-title-field')), findsNothing);
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text(title)),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('search-notes-field')),
      'zzz-tidak-ada',
    );
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada catatan yang cocok.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-notes-field')), title);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text(title)),
      findsOneWidget,
    );
  });
}
