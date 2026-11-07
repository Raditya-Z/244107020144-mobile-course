import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class RecordingNoteRepository extends NoteRepository {
  RecordingNoteRepository() : super(openDb: () => throw UnimplementedError());

  final List<Note> notes = [];
  int addCalls = 0;
  String? addedTitle;

  @override
  Future<List<Note>> fetchNotes() async => List<Note>.of(notes);

  @override
  Future<int> countDirty() async => notes.where((note) => note.dirty).length;

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    addCalls++;
    addedTitle = title;
    final note = Note(
      id: addCalls,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    notes.add(note);
    return note;
  }
}

Future<void> pumpNotesPage(
  WidgetTester tester,
  RecordingNoteRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('judul kosong menampilkan pesan dan tidak menyimpan catatan', (
    tester,
  ) async {
    final repository = RecordingNoteRepository();
    await pumpNotesPage(tester, repository);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(repository.addCalls, 0);
  });

  testWidgets('pesan validasi dibersihkan setelah catatan berhasil disimpan', (
    tester,
  ) async {
    final repository = RecordingNoteRepository();
    await pumpNotesPage(tester, repository);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, ' Catatan ');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(repository.addedTitle, 'Catatan');
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Tambah Catatan'), findsNothing);
    expect(find.text('Judul tidak boleh kosong'), findsNothing);
  });
}
