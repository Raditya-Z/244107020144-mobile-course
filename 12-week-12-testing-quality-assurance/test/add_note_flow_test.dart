import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

import 'support/note_fakes.dart';

Widget pageWith(FakeNoteRepository repository) {
  return ProviderScope(
    overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: NotesPage()),
  );
}

Future<void> openAddSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('add-note-fab')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tampilan awal menampilkan daftar catatan dari repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      pageWith(
        FakeNoteRepository(
          items: [
            Note(title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1)),
            Note(title: 'Tugas pemrograman', updatedAt: DateTime(2026, 11, 2)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belanja bulanan'), findsOneWidget);
    expect(find.text('Tugas pemrograman'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('tombol simpan nonaktif saat judul hanya berisi spasi', (
    tester,
  ) async {
    final repository = FakeNoteRepository();
    await tester.pumpWidget(pageWith(repository));
    await tester.pumpAndSettle();

    await openAddSheet(tester);
    await tester.enterText(find.byKey(const Key('note-title-field')), '   ');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('save-note-button')),
    );
    expect(button.onPressed, isNull);
    expect(repository.addedTitles, isEmpty);
  });

  testWidgets('judul valid disimpan dan muncul di daftar', (tester) async {
    final repository = FakeNoteRepository();
    await tester.pumpWidget(pageWith(repository));
    await tester.pumpAndSettle();

    await openAddSheet(tester);
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      '  Baca materi  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(repository.addedTitles, ['Baca materi']);
    expect(find.text('Catatan tersimpan'), findsOneWidget);
    expect(find.text('Baca materi'), findsOneWidget);
  });

  testWidgets('kegagalan simpan ditampilkan sebagai pesan dari failure', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      addFailure: const LocalFailure(
        'Catatan gagal disimpan. Silakan coba lagi.',
      ),
    );
    await tester.pumpWidget(pageWith(repository));
    await tester.pumpAndSettle();

    await openAddSheet(tester);
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Baca materi',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Catatan gagal disimpan. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Belum ada catatan.'), findsOneWidget);
  });
}
