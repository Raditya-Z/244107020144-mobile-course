# Week 9 — AI-Assisted Development / Vibe Coding

Praktikum Minggu 9 menambahkan satu fitur kecil ke aplikasi **Campus Notify** (hasil refactor Clean Architecture Minggu 7) dengan workflow AI: **Prompt → Generate → Verify → Test → Refactor → Explain**. Project Minggu 7 tidak diubah; working copy project dibuat di folder ini (`campus_notify/`) dan semua perubahan terjadi di dalamnya.

## Fitur yang dibuat

**Search Notes** — pencarian judul catatan di halaman Catatan:

- Kolom "Cari judul catatan" di bawah AppBar; hasil terfilter saat mengetik.
- Pencarian **tidak case-sensitive** (`belanja` tetap menemukan "Belanja bulanan").
- Kueri kosong + daftar kosong menampilkan `Belum ada catatan.` (perilaku lama dipertahankan); kueri tidak cocok menampilkan empty state `Tidak ada catatan yang cocok.`.
- Logika filter berada di use case domain murni (`SearchNotes`), state kueri di `NotifierProvider`, akses data tetap lewat `NoteRepository` — tidak ada SQLite di widget.
- Ikut dilengkapi jalur masuk minimal (route `/notes`, tombol "Buka Catatan" di Home, FAB tambah catatan memakai kontrak `addNote` yang sudah ada) karena hasil review AI menunjukkan halaman tersebut sebelumnya tidak terhubung ke router, sehingga uji manual tidak mungkin dilakukan. Detail keputusan di `docs/ai-log.md` §8.

## Prompt yang digunakan (formula 5 slot)

```text
Peran: senior Flutter dev
Konteks: project campus_notify, feature-first (presentation->domain<-data),
  Riverpod 3 (flutter_riverpod ^3.4.3), SQLite via sqflite ^2.4.5 + Dio.
  NotesPage saat ini ConsumerWidget yang watch notesProvider (FutureProvider<List<Note>>),
  daftar note di-load lewat use case GetNotes -> NoteRepository.fetchNotes().
Tugas: tambah pencarian judul notes di NotesPage: search bar di AppBar,
  hasil terfilter saat diketik, empty state "Tidak ada catatan yang cocok"
  ketika query tidak menemukan apa pun. Pencarian tidak case-sensitive.
Batas: jangan ubah arsitektur dan jangan tambah package; jangan ubah kontrak
  NoteRepository/GetNotes; jangan panggil SQLite dari widget; maks 80 baris per file.
Output: kode implementasi + 3 test case (query cocok, query tak cocok,
  case-insensitive) + 1 widget test empty state + cara jalankan analyze dan test.
```

Prompt mentah, output awal AI, hasil verifikasi, tabel terima/tolak, dan bukti lengkap ada di [`docs/ai-log.md`](docs/ai-log.md).

## Stack

Sesuai `pubspec.yaml` project (tidak ada dependency baru): Flutter & Dart (SDK ^3.13.1), Riverpod 3 (`flutter_riverpod ^3.4.3`), GoRouter, SQLite (`sqflite ^2.4.5`), Dio, flutter_lints 6.

## Cara menjalankan

Dari root repository:

```powershell
cd 09-week-9-ai-assisted-development/campus_notify
flutter pub get
flutter run
```

Login memakai email apa pun yang mengandung `@` dan password minimal 6 karakter (mis. `test@demo.id` / `password123`), lalu **Buka Catatan** → tambah catatan lewat tombol **Catatan** (FAB) → cari lewat kolom "Cari judul catatan".

## Hasil pemeriksaan mesin

Dijalankan di `09-week-9-ai-assisted-development/campus_notify`:

```text
$ dart format --set-exit-if-changed .
Formatted 31 files (0 changed)

$ flutter analyze
No issues found!

$ flutter test
+21: All tests passed!
```

Rincian test: `test/search_filter_test.dart` (4 unit test use case `SearchNotes`: cocok, tak cocok, case-insensitive, kueri whitespace), `test/notes_page_search_test.dart` (5 widget test: empty state tak cocok, hasil terfilter, pesan daftar kosong lama, kebocoran kueri antar-sesi halaman, pesan failure tanpa prefix Exception), plus 12 test baseline Minggu 7 yang tetap lulus — fungsi lama tidak rusak.

## Bukti uji manual

Tiga kondisi pencarian pada perangkat Android (CPH2473, Android 14), diambil via `adb screencap` sementara aplikasi berjalan dan terlihat di jendela scrcpy:

| Kondisi | Screenshot |
|---|---|
| Kueri kosong — daftar penuh 3 catatan | `screenshots/01-query-kosong-daftar.png` |
| Kueri `belanja` — 2 hasil, bukti case-insensitive | `screenshots/02-query-cocok-hasil.png` |
| Kueri `zzz-tak-cocok` — empty state | `screenshots/03-query-tak-cocok-empty-state.png` |

## Refleksi

Ringkasan dari refleksi lengkap di `docs/ai-log.md` §10:

1. **Halusinasi AI yang ditemukan:** path import `../domain/entities/note.dart` yang tidak ada di struktur folder nyata (seharusnya `../../domain/...`), terbukti dari 3 error `flutter analyze`; plus regresi pesan empty state yang dibuktikan test merah.
2. **Prompt paling membantu:** slot Batas ("jangan ubah arsitektur, jangan panggil SQLite dari widget, maks 80 baris") — dari situlah temuan verifikasi terbanyak muncul. Yang akan diubah: menyebut perilaku lama yang harus dipertahankan agar tidak hilang saat AI menulis ulang halaman.
3. **Refactor pada kode AI:** `filterNotes` pindah dari file widget ke use case domain murni `SearchNotes`; state kueri pindah dari `setState` lokal ke `NotifierProvider` dengan `isAutoDispose: true`.
4. **Keputusan tersulit:** temuan review AI soal route `/notes` yang tidak ada — faktanya benar, tapi menyentuh file di luar fitur search; diputuskan terima-minim karena uji manual jobsheet tidak mungkin jalan tanpa jalur masuk, sambil menolak usulan AddNote use case baru dan router test sebagai di luar scope.

## Struktur folder Minggu 9

```text
09-week-9-ai-assisted-development/
  campus_notify/   # working copy project Minggu 7 + fitur search (sumber kode)
  docs/ai-log.md   # prompt, output awal AI, verifikasi, bukti bug, tabel keputusan
  screenshots/     # bukti uji manual 3 kondisi
  README.md
```
