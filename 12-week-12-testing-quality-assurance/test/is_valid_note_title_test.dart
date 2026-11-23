import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/note_validation.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';

import 'support/note_fakes.dart';

void main() {
  group('isValidNoteTitle', () {
    test('menerima judul yang berisi teks', () {
      expect(isValidNoteTitle('Belajar Flutter'), isTrue);
    });

    test('menerima teks yang diapit spasi', () {
      expect(isValidNoteTitle('  Baca materi  '), isTrue);
    });

    test('menolak teks kosong', () {
      expect(isValidNoteTitle(''), isFalse);
    });

    test('menolak teks yang hanya berisi spasi', () {
      // Kasus tepi: pengguna mengetik spasi saja, secara visual "ada isi"
      // tetapi tidak ada teks yang bisa disimpan.
      expect(isValidNoteTitle('   '), isFalse);
      expect(isValidNoteTitle('\t\n'), isFalse);
    });
  });

  group('AddNote', () {
    test('merapikan spasi tepi sebelum diteruskan ke repository', () async {
      final repository = FakeNoteRepository();
      final result = await AddNote(repository)(title: '  Belajar Flutter  ');

      expect(result.failure, isNull);
      expect(result.note?.title, 'Belajar Flutter');
      expect(repository.addedTitles, ['Belajar Flutter']);
    });

    test('menolak judul kosong tanpa memanggil repository', () async {
      final repository = FakeNoteRepository();
      final useCase = AddNote(repository);

      for (final title in ['', '   ']) {
        final result = await useCase(title: title);

        expect(result.note, isNull);
        expect(result.failure, isA<LocalFailure>());
        expect(result.failure?.message, 'Judul catatan tidak boleh kosong.');
      }

      expect(repository.addedTitles, isEmpty);
    });

    test('meneruskan kegagalan repository apa adanya', () async {
      final repository = FakeNoteRepository(
        addFailure: const LocalFailure(
          'Catatan gagal disimpan. Silakan coba lagi.',
        ),
      );

      final result = await AddNote(repository)(title: 'Belajar Flutter');

      expect(result.note, isNull);
      expect(result.failure, isA<LocalFailure>());
      expect(
        result.failure?.message,
        'Catatan gagal disimpan. Silakan coba lagi.',
      );
      expect(repository.addedTitles, ['Belajar Flutter']);
    });
  });
}
