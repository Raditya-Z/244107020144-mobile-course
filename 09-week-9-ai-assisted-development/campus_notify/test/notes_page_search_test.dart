import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  int fetches = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    fetches++;
    if (fail) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('Catatan gagal dimuat. Silakan coba lagi.'),
      );
    }

    return (notes: items, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    throw UnimplementedError();
  }
}

Widget pageWith(List<Note> items) {
  return ProviderScope(
    overrides: [
      noteRepositoryProvider.overrideWithValue(
        FakeNoteRepository(items: items),
      ),
    ],
    child: const MaterialApp(home: NotesPage()),
  );
}

void main() {
  testWidgets('query tak cocok menampilkan empty state', (tester) async {
    await tester.pumpWidget(
      pageWith([
        Note(title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1)),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz-tak-ada');
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada catatan yang cocok.'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('query cocok menampilkan hasil terfilter', (tester) async {
    await tester.pumpWidget(
      pageWith([
        Note(title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1)),
        Note(title: 'Tugas pemrograman', updatedAt: DateTime(2026, 11, 2)),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'BELANJA');
    await tester.pumpAndSettle();

    expect(find.text('Belanja bulanan'), findsOneWidget);
    expect(find.text('Tugas pemrograman'), findsNothing);
  });

  testWidgets('daftar kosong tanpa kueri tetap menampilkan pesan lama', (
    tester,
  ) async {
    await tester.pumpWidget(pageWith(const []));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada catatan.'), findsOneWidget);
  });

  testWidgets('kueri tidak bocor saat halaman dibuka ulang', (tester) async {
    final repo = FakeNoteRepository(
      items: [Note(title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1))],
    );

    Widget appWith(Widget home) {
      return ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: home),
      );
    }

    await tester.pumpWidget(appWith(const NotesPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz-tak-ada');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada catatan yang cocok.'), findsOneWidget);

    // Pindah halaman (NotesPage di-unmount), lalu kembali lagi.
    await tester.pumpWidget(
      appWith(const Scaffold(body: Center(child: Text('Halaman lain')))),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(appWith(const NotesPage()));
    await tester.pumpAndSettle();

    // Halaman baru harus tampil netral: daftar terlihat, tidak tersaring
    // oleh kueri yang tidak terlihat di kolom pencarian.
    expect(find.text('Belanja bulanan'), findsOneWidget);
    expect(find.text('zzz-tak-ada'), findsNothing);
  });

  testWidgets('failure repository ditampilkan sebagai pesan ramah', (
    tester,
  ) async {
    final repo = FakeNoteRepository(fail: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Catatan gagal dimuat. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.textContaining('Exception:'), findsNothing);

    // Riverpod 3 me-retry provider yang gagal dengan backoff (default
    // retryCount 1..10, lihat sumber paket), jadi yang diuji adalah
    // pertambahan fetch saat "Coba Lagi", bukan jumlah pastinya.
    expect(repo.fetches, greaterThanOrEqualTo(1));
    final before = repo.fetches;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(repo.fetches, greaterThan(before));
  });
}
