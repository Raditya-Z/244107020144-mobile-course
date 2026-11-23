import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notes_database.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';
import '../../domain/entities/note.dart';

// Data layer: database opener disuntikkan.
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi repository.
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

// Domain layer: aturan filter judul hidup di use case murni.
final searchNotesProvider = Provider<SearchNotes>((ref) {
  return const SearchNotes();
});

// Presentation layer: teks kueri pencarian dipegang notifier, bukan widget.
// isAutoDispose: siklus hidup state kueri disamakan dengan halaman, supaya
// kueri lama tidak menyaring daftar saat halaman dibuka ulang (bug temuan
// review AI, dibuktikan test 'kueri tidak bocor saat halaman dibuka ulang').
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
  isAutoDispose: true,
);

// Presentation layer: state untuk UI.
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();

  if (result.failure != null) {
    // Failure dilempar apa adanya; UI menampilkan .message yang ramah,
    // tanpa prefix "Exception: " (bug temuan review AI).
    throw result.failure!;
  }

  return result.notes;
});
