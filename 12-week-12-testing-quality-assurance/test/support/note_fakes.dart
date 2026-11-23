import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';

/// Fake repository: implementasi sederhana yang perilakunya dikendalikan
/// pengujian, sehingga test tidak bergantung pada SQLite atau jaringan.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({
    List<Note> items = const [],
    this.fetchFailure,
    this.addFailure,
  }) : items = [...items];

  final List<Note> items;
  final Failure? fetchFailure;
  final Failure? addFailure;

  final List<String> addedTitles = [];
  int fetchCalls = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    fetchCalls++;
    if (fetchFailure != null) {
      return (notes: const <Note>[], failure: fetchFailure);
    }

    return (notes: List<Note>.unmodifiable(items), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addedTitles.add(title);
    if (addFailure != null) {
      return (note: null, failure: addFailure);
    }

    final note = Note(
      id: items.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 24),
    );
    items.insert(0, note);

    return (note: note, failure: null);
  }
}
