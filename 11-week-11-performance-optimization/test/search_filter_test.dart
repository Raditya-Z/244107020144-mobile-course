import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/usecases/search_notes.dart';

void main() {
  const search = SearchNotes();
  final list = [
    Note(title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1)),
    Note(title: 'Rencana belanja buku', updatedAt: DateTime(2026, 11, 2)),
    Note(title: 'Tugas pemrograman', updatedAt: DateTime(2026, 11, 3)),
  ];

  test('query cocok mengembalikan catatan yang sesuai', () {
    expect(search(notes: list, query: 'belanja'), hasLength(2));
  });

  test('query tak cocok mengembalikan kosong', () {
    expect(search(notes: list, query: 'zzz-tak-ada'), isEmpty);
  });

  test('pencarian mengabaikan besar kecil huruf', () {
    expect(search(notes: list, query: 'BELANJA'), hasLength(2));
    expect(search(notes: list, query: 'Belanja'), hasLength(2));
  });

  test('query kosong mengembalikan semua catatan', () {
    expect(search(notes: list, query: '   '), hasLength(3));
  });
}
