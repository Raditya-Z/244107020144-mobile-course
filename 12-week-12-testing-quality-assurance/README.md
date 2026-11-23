# Week 12 — Testing & Quality Assurance

Folder ini berisi aplikasi `campus_notify` (kelanjutan Minggu 11) yang dilengkapi
pengujian unit, widget, dan integrasi sesuai modul
[12 - Pengujian dan Jaminan Kualitas](https://jti-polinema.github.io/flutter-codelab/12-minggu-12-testing-quality-assurance/index.html).

## Fitur yang diuji

| Fitur | Perilaku penting |
| --- | --- |
| Catatan | Menambah catatan, validasi judul, pencarian judul, pesan error |
| Login | Sesi disimpan di token store (dipakai integration test lewat override) |
| Asisten AI | Chat, OCR, speech, gambar (suite pengujian Minggu 10/11 tetap dijalankan) |

## Pembagian jenis pengujian

| Jenis | Yang diperiksa | Lokasi |
| --- | --- | --- |
| Unit | Aturan validasi judul dan use case `AddNote` | `test/is_valid_note_title_test.dart` |
| Unit (dependensi) | `GetNotes`, `SearchNotes`, cache/fallback AI dengan fake | `test/get_notes_test.dart`, `test/search_filter_test.dart`, `test/ai_*_test.dart` |
| Widget | Tampilan awal, input tidak valid, simpan berhasil, error simpan, pencarian | `test/add_note_flow_test.dart`, `test/notes_page_search_test.dart` |
| Integrasi | Alur home → daftar catatan → tambah → cari pada perangkat | `integration_test/app_test.dart` |

## Skenario yang dicatat

| # | Skenario | Jenis | Harapan |
| --- | --- | --- | --- |
| 1 | Judul berisi teks, mis. `  Baca materi  ` | Sukses | Spasi tepi dirapikan, catatan tersimpan dan muncul di daftar |
| 2 | Judul kosong atau hanya spasi (`   `, `\t\n`) | Kasus tepi | Ditolak: tombol Simpan nonaktif, use case mengembalikan `LocalFailure` tanpa memanggil repository |
| 3 | Repository gagal menyimpan | Kegagalan | Pesan failure ditampilkan apa adanya, daftar tidak berubah |
| 4 | Kueri pencarian tidak cocok | Kasus tepi | Empty state "Tidak ada catatan yang cocok." |
| 5 | Alur pengguna dari halaman utama sampai catatan baru terlihat | Integrasi | Catatan tersimpan di SQLite perangkat dan dapat ditemukan lewat pencarian |

## Kode yang disiapkan agar mudah diuji

- `lib/features/notes/domain/note_validation.dart` — aturan murni `isValidNoteTitle`
  (dipisah dari widget agar bisa diuji unit).
- `lib/features/notes/domain/usecases/add_note.dart` — use case `AddNote`
  memvalidasi judul lalu meneruskan ke `NoteRepository`; validasi tidak hanya
  bergantung pada tombol di UI.
- `lib/features/notes/presentation/providers/notes_providers.dart` — `addNoteProvider`
  agar sheet tetap memakai abstraksi repository.
- `test/support/note_fakes.dart` — `FakeNoteRepository` dengan mode sukses,
  daftar kosong, dan kegagalan, tanpa SQLite atau jaringan.
- `Key` untuk kontrol utama: `add-note-fab`, `note-title-field`,
  `save-note-button`, `search-notes-field`.

## Menjalankan

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage

# butuh perangkat/emulator aktif (contoh: Android CPH2473)
flutter test integration_test/app_test.dart -d 9d35dde2
```

## Hasil pemeriksaan

| Pemeriksaan | Hasil |
| --- | --- |
| `dart format --set-exit-if-changed lib test integration_test` | 63 file, 0 berubah |
| `flutter analyze` | No issues found! |
| `flutter test` | **+60: All tests passed!** (49 suite lama + 11 test baru) |
| `flutter test integration_test/app_test.dart -d 9d35dde2` | **+1: All tests passed!** (±9 detik setelah APK terpasang) |
| `flutter test --coverage` | 629/780 baris = **80,6%** cakupan baris |

### Cakupan fitur catatan

| File | Cakupan baris |
| --- | --- |
| `domain/note_validation.dart` | 100% (1/1) |
| `domain/usecases/add_note.dart` | 100% (5/5) |
| `domain/usecases/get_notes.dart` | 100% (3/3) |
| `domain/usecases/search_notes.dart` | 100% (6/6) |
| `presentation/pages/notes_page.dart` | 100% (43/43) |
| `presentation/widgets/add_note_sheet.dart` | 100% (28/28) |
| `presentation/providers/notes_providers.dart` | 91,7% (11/12) |
| `data/repositories/note_repository_impl.dart` | 0% — memerlukan SQLite perangkat, diverifikasi lewat integration test |

Laporan lcov ada di `coverage/lcov.info` (folder `coverage/` diabaikan Git karena
merupakan artefak hasil pengujian).

## Catatan integration test

- Root aplikasi untuk test memakai `ProviderScope` dengan override `authProvider`
  (sesi login disimulasikan) supaya alur tidak bergantung pada API autentikasi.
- Router, halaman, use case, dan repository SQLite yang dipakai tetap implementasi
  nyata di perangkat, sehingga alur tambah + cari catatan benar-benar menyentuh DB.
- Inisialisasi Firebase/push (`main()`) tidak dijalankan di test karena tidak
  dibutuhkan alur catatan; halaman diuji lewat `MaterialApp.router` dengan
  `routerProvider` yang sama.
- Judul catatan memakai nilai unik (timestamp) agar test tetap lulus ketika
  dijalankan berulang di perangkat yang sama.

## Temuan yang belum terselesaikan

1. `NoteRepositoryImpl`, `NoteModel`, dan `notes_database` belum punya unit test
   karena bergantung pada sqflite (method channel). Perilakunya diverifikasi lewat
   integration test dan pengujian manual; unit test dengan sqflite FFI dianggap
   di luar cakupan modul ini.
2. `AiKeyStore` dan `AiStorage` (0% cakupan) bergantung pada `flutter_secure_storage`
   dan `path_provider`; pengujian di widget test diganti fake (lihat
   `test/support/ai_fakes.dart`), implementasi aslinya belum diuji otomatis.
3. Integration test belum bisa dijalankan di CI karena memerlukan perangkat/emulator;
   langkah `flutter test` di CI hanya menjalankan unit dan widget test.
4. `flutter test --coverage` tidak mengukur baris yang dijalankan integration test,
   sehingga angka 80,6% lebih rendah dari cakupan perilaku sebenarnya.
5. `routes.dart` (konstanta path) tidak tereksekusi di test, jadi muncul 0%.

## Refleksi

**Bug apa yang paling mungkin terlewat tanpa pengujian yang Anda tulis?**

Kasus "judul hanya berisi spasi" dan dua jalur kegagalan simpan. Tanpa test,
tombol yang tetap aktif untuk input spasi dan pesan error yang hilang saat
repository gagal mudah lolos karena di layar semuanya tampak normal. Test
validasi juga mengunci perapian spasi tepi, yang dulunya hanya tersirat di widget.

**Bagian mana yang perlu fake, dan bagaimana fake itu membuat pengujian lebih konsisten?**

Repository catatan (SQLite) dan layanan AI (jaringan + secure storage). Dengan
`FakeNoteRepository`, hasil sukses, daftar kosong, dan failure bisa ditentukan
persis, sehingga test tidak bergantung pada isi database perangkat, waktu, atau
koneksi internet. Fake juga mencatat judul yang diterima `addNote`, sehingga
"apakah repository benar-benar dipanggil" dapat diperiksa.

**Apa perbedaan nilai yang diberikan pengujian widget dan pengujian integrasi pada fitur Anda?**

Widget test cepat dan presisi untuk aturan UI: tombol nonaktif untuk input tidak
valid, snackbar error, state kosong, dan pemfilteran daftar tanpa perangkat.
Integration test memastikan bagian-bagian itu benar-benar terhubung — router,
halaman, use case, dan SQLite — sehingga catatan yang diketik benar-benar
tersimpan dan bisa ditemukan lewat pencarian pada perangkat nyata.

## Catatan penggunaan AI

Skenario dan pesan kegagalan disusun dengan bantuan AI, tetapi setiap pengujian
diperiksa manual: assertion menyasar perilaku yang terlihat pengguna (teks daftar,
snackbar, status tombol, catatan pemanggilan repository), bukan sekadar "tidak
melempar exception". Tidak ada API key atau kredensial yang disimpan di repository.
