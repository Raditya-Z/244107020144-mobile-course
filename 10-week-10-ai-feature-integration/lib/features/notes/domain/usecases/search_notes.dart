import '../entities/note.dart';

/// Aturan murni pencarian judul catatan: tidak peka huruf besar/kecil,
/// spasi di awal/akhir diabaikan, kueri kosong berarti tampilkan semua.
class SearchNotes {
  const SearchNotes();

  List<Note> call({required List<Note> notes, required String query}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return notes;
    }

    return notes
        .where((note) => note.title.toLowerCase().contains(normalized))
        .toList();
  }
}
