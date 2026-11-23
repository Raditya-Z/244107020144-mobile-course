/// Aturan bisnis murni: judul catatan harus berisi teks setelah spasi
/// di awal/akhir diabaikan. Dipisahkan dari widget supaya bisa diuji tanpa UI.
bool isValidNoteTitle(String value) => value.trim().isNotEmpty;
