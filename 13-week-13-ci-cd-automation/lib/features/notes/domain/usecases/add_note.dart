import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../note_validation.dart';
import '../repositories/note_repository.dart';

/// Validasi judul hidup di domain, bukan hanya di widget, sehingga aturan
/// bisnis tetap berlaku untuk jalur mana pun yang memanggil use case ini.
class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    final trimmed = title.trim();

    if (!isValidNoteTitle(trimmed)) {
      return (
        note: null,
        failure: const LocalFailure('Judul catatan tidak boleh kosong.'),
      );
    }

    return _repository.addNote(title: trimmed, body: body);
  }
}
