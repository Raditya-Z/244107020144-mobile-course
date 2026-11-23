import 'package:campus_notify/ai/ai_cache.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/ai/ai_usage_limiter.dart';
import 'package:campus_notify/features/ai/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/ai/presentation/providers/ai_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/ai_fakes.dart';

class _FakeAiService extends AiService {
  _FakeAiService() : super(keyStore: FakeAiKeyStore('test-key'));

  int calls = 0;

  @override
  Stream<String> askStream(
    String question, {
    List<AiTurn> history = const [],
  }) async* {
    calls++;
    yield 'Halo';
    yield ' dunia';
  }
}

Widget _app({String? key, AiService? service, MemoryAiStorage? storage}) {
  final memory = storage ?? MemoryAiStorage();

  return ProviderScope(
    overrides: [
      aiStorageProvider.overrideWithValue(memory),
      aiKeyStoreProvider.overrideWithValue(FakeAiKeyStore(key)),
      if (service != null) aiServiceProvider.overrideWithValue(service),
    ],
    child: const MaterialApp(home: Scaffold(body: ChatScreen())),
  );
}

String _selectableText(WidgetTester tester) {
  return tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((widget) => widget.data ?? '')
      .join('\n');
}

void main() {
  testWidgets('tanpa kunci API menampilkan dialog dan fallback offline', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('Kunci API belum diatur'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Apa itu Campus Notify?');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Kunci API Belum Diatur'), findsOneWidget);
    expect(find.text('Mode Offline'), findsOneWidget);

    await tester.tap(find.text('Mode Offline'));
    await tester.pumpAndSettle();

    expect(_selectableText(tester), contains('Campus Notify membantu'));
    expect(find.text('Mode offline'), findsOneWidget);

    // Data pribadi tidak dikirim, tetapi pesan pengguna tetap ditampilkan.
    expect(find.text('Apa itu Campus Notify?'), findsOneWidget);
  });

  testWidgets('data pribadi ditandai telah disamarkan', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'HP saya 081234567890');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 data pribadi disamarkan'), findsOneWidget);

    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Kunci API Belum Diatur'), findsNothing);
  });

  testWidgets(
    'streaming menampilkan jawaban dan cache mencegah panggilan ulang',
    (tester) async {
      final storage = MemoryAiStorage();
      final service = _FakeAiService();

      await tester.pumpWidget(
        _app(key: 'test-key', service: service, storage: storage),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Halo');
      await tester.tap(find.byTooltip('Kirim'));
      await tester.pumpAndSettle();

      expect(_selectableText(tester), contains('Halo dunia'));
      expect(service.calls, 1);
      expect(storage.values[AiUsageLimiter.storageKey], contains('"count":1'));
      expect(storage.values[AiResponseCache.storageKey], isNotNull);

      await tester.enterText(find.byType(TextField), 'Halo');
      await tester.tap(find.byTooltip('Kirim'));
      await tester.pumpAndSettle();

      expect(service.calls, 1);
      expect(find.text('Dari cache lokal'), findsOneWidget);
    },
  );
}
