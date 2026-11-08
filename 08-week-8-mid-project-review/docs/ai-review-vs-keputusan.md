# AI Review vs Keputusan Final

Dokumen ini membandingkan saran AI coding assistant dengan hasil verifikasi teknis dan keputusan akhir. Lengkapi setelah AI menghasilkan review PR. Jangan menganggap saran AI sebagai temuan benar sebelum dibuktikan.

## Prompt yang digunakan

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data), Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

## Informasi PR yang direview

- PR: [#1](https://github.com/Raditya-Z/244107020144-mobile-course/pull/1)
- Source branch lokal: `feat/notes-validation`
- Target branch yang dimaksud praktikum: `develop`
- Commit/diff lokal yang dicocokkan: `91f2566 fix(notes): tampilkan pesan saat judul kosong`; menambahkan pemanggilan SnackBar di `05-week-5-local-storage-offline-first/week5_offline_notes/lib/pages/notes_page.dart`.
- Tanggal review: 2026-11-07
- Status PR: merged; remote-tracking ref lokal `origin/develop` memuat merge commit `06ec524 Merge pull request #1 from Raditya-Z/feat/notes-validation`.

## Output awal AI

PR [#1](https://github.com/Raditya-Z/244107020144-mobile-course/pull/1) sudah **merged**. Diff-nya hanya menambahkan validasi di `notes_page.dart`. Berikut lima temuan teratas, diurutkan berdasarkan dampak:

| # | Level | Temuan dan dampak |
|---|---|---|
| 1 | **Blocker** | **Pesan validasi berisiko tertutup dialog.** `SnackBar` ditampilkan pada `Scaffold` di belakang `AlertDialog`, jadi pengguna mungkin tidak melihat alasan tombol Simpan tidak bekerja. Tampilkan error langsung pada field, misalnya dengan `TextFormField.validator`, atau `errorText` di dalam dialog. Contoh: `TextFormField(validator: (v) => (v?.trim().isEmpty ?? true) ? 'Judul tidak boleh kosong' : null)`. |
| 2 | **Saran** | **Pesan validasi bisa tertinggal setelah judul diperbaiki.** Jika pengguna menekan Simpan beberapa kali, pesan dapat mengantre; setelah catatan berhasil disimpan dan dialog ditutup, pesan lama masih bisa muncul. Validasi inline menghindari antrean ini. Jika tetap memakai `SnackBar`, bersihkan pesan tertunda sebelum menutup dialog, misalnya `ScaffoldMessenger.of(context).clearSnackBars();`. |
| 3 | **Saran** | **Aturan judul kosong hanya berlaku di UI.** `NoteRepository.addNote` menerima dan menyimpan judul apa pun, termasuk string kosong, sehingga pemanggil lain dapat melewati validasi. Untuk aturan yang harus berlaku di semua jalur, validasi di use case/domain sebelum memanggil repository: `final title = rawTitle.trim(); if (title.isEmpty) throw const InvalidNoteTitle(); return repository.addNote(title: title, body: body.trim());`. UI kemudian menerjemahkan `InvalidNoteTitle` menjadi pesan yang sesuai. |
| 4 | **Saran** | **Belum ada test untuk jalur judul kosong.** Test di `note_test.dart` menguji model dan provider, bukan interaksi form yang diubah. Tambahkan widget test yang memeriksa judul kosong dan whitespace-only menampilkan error serta tidak memanggil `addNote`: `expect(find.text('Judul tidak boleh kosong'), findsOneWidget); expect(repository.addCalls, 0);`. |
| 5 | **Saran** | **Jalur sukses form juga belum dites.** Tambahkan widget test untuk memastikan judul valid tetap tersimpan setelah normalisasi dan dialog tertutup. Contoh assertion: `expect(repository.addedTitle, 'Catatan'); expect(find.text('Tambah Catatan'), findsNothing);`. Ini menjaga perilaku lama saat menambahkan validasi. |

Status GitHub PR melaporkan **tidak ada check yang tercatat**. Review ini berdasarkan diff dan kode terkait; test tidak dijalankan.

## Verifikasi dan keputusan

Isi satu baris untuk setiap temuan AI. Sertakan bukti seperti hasil grep, test gagal/lulus, atau reproduksi manual. Tolak saran yang melanggar dependency rule.

| # | Temuan AI dan level | Bukti verifikasi | Apakah melanggar dependency rule? | Keputusan final | Alasan teknis dan tindakan |
|---|---|---|---|---|---|
| 1 | Blocker - SnackBar mungkin tertutup dialog; sarannya memakai `TextFormField.validator`. | Screenshot [dialog terbuka](../screenshots/Manual-validasi-dialog-terbuka.jpg) menunjukkan pesan `Judul tidak boleh kosong` terlihat di bawah dialog saat dialog masih terbuka. Diff commit sebenarnya hanya menambahkan SnackBar; guard `if (titleController.text.trim().isEmpty) return;` sudah ada sebelumnya. | Tidak terkait dependency rule. | **Ditolak sebagai bug pada skenario yang diuji. Potongan kode validator juga ditolak sebagai solusi lengkap.** | Reproduksi manual menunjukkan pesan terlihat, sehingga klaim bahwa pesan tertutup tidak terjadi pada perangkat/skenario ini. `validator` juga tidak cukup jika hanya mengganti widget: harus ada `Form` dan pemanggilan `FormState.validate()` ketika tombol Simpan ditekan. |
| 2 | Saran - SnackBar berulang dapat tertinggal setelah judul diperbaiki dan dialog ditutup. | Screenshot [setelah catatan tersimpan](../screenshots/Manual-validasi-setelah-simpan.jpg) menunjukkan catatan `hdhdkcmc` tersimpan (`Belum sync: 1`) sementara pesan SnackBar masih terlihat setelah dialog tertutup. Widget test baru memverifikasi pesan validasi dibersihkan setelah save sukses. | Tidak terkait dependency rule. | **Diterima dan ditangani.** | Setelah penyimpanan sukses, `ScaffoldMessengerState.clearSnackBars()` membersihkan SnackBar aktif dan yang menunggu. Widget test memastikan catatan tersimpan, dialog tertutup, dan pesan validasi hilang. Screenshot membuktikan perilaku lama; widget test membuktikan perbaikan. |
| 3 | Saran - Repository menerima judul kosong; AI menyarankan menambahkan use case/domain validation. | `NoteRepository.addNote` menerima `required String title` dan langsung memasukkan nilainya ke `Note` lalu database tanpa memeriksa `trim().isEmpty`. Pencarian pemanggil menunjukkan pemanggilan aplikasi saat ini hanya dari `NotesPage`. | **Tidak ada pelanggaran dependency rule yang dibuktikan oleh temuan ini.** | **Fakta batas repository diterima; saran menambah use case/domain ditolak untuk PR ini.** | Aplikasi Minggu 5 yang diubah memakai `pages` dan `data`, bukan feature-first/domain use case seperti konteks prompt Copilot. Menambah lapisan domain untuk satu validasi di PR UI ini tidak didukung oleh struktur proyek saat ini. Jika aturan harus dijamin bagi semua pemanggil, buat perubahan arsitektur terpisah dan konsisten dengan desain aplikasi. |
| 4 | Saran - Tidak ada test untuk validasi judul kosong. | `test/notes_page_validation_test.dart` mengisi judul whitespace, menekan Simpan, lalu memeriksa pesan error, dialog tetap terbuka, dan `addCalls` tetap 0. | Tidak terkait dependency rule. | **Diterima dan ditangani.** | Widget test baru mencakup validasi input whitespace dan membuktikan repository tidak dipanggil. Test lulus. |
| 5 | Saran - Jalur sukses form juga belum dites. | Test kedua di `test/notes_page_validation_test.dart` memperbaiki judul menjadi ` Catatan `, menyimpan, lalu memeriksa judul tersimpan sebagai `Catatan`, dialog tertutup, dan SnackBar hilang. | Tidak terkait dependency rule. | **Diterima dan ditangani.** | Widget test baru mencakup jalur error-lalu-sukses, termasuk normalisasi judul dan dismiss dialog. Test lulus. |

## Ringkasan verifikasi

- Jumlah temuan AI yang terbukti benar: 4 (temuan 2-5; temuan #2 dikonfirmasi screenshot, lalu ditangani dan diverifikasi dengan widget test).
- Jumlah temuan yang ditolak: 1 (temuan 1 ditolak sebagai bug pada skenario yang diuji karena screenshot menunjukkan pesan terlihat; potongan `TextFormField.validator` juga belum lengkap tanpa `Form` dan `validate()`).
- Bukti test/analyze/manual: inspeksi diff `91f2566`, `NoteRepository.addNote`, seluruh pemanggilan `addNote`, isi test lama dan widget test baru, queue SnackBar pada Flutter SDK lokal, serta dua screenshot reproduksi manual pada folder `screenshots/`. Hasil final: `flutter test` lulus dengan 6 test; `flutter analyze` lulus tanpa masalah; `dart format --set-exit-if-changed .` melaporkan 16 file dan 0 perubahan.
- Keputusan review final: temuan SnackBar tertutup dialog ditolak berdasarkan reproduksi visual. Pesan yang tertinggal setelah save sukses ditangani dengan membersihkan SnackBar dan diverifikasi oleh widget test. Kekurangan test juga ditangani. Usulan menambah use case ditolak untuk PR ini, sambil mencatat bahwa repository belum menjaga aturan judul bagi pemanggil lain.
- Alasan teknis keputusan final: output AI mencampur konteks Clean Architecture Minggu 7 dengan diff aplikasi catatan Minggu 5. Verifikasi mengikuti kode aktual dan memisahkan fakta yang terbukti dari dugaan/perbaikan yang diusulkan.

## Catatan akurasi output Copilot

Copilot menulis bahwa diff menambahkan validasi. Diff lokal commit `91f2566` menunjukkan perubahan yang ditambahkan adalah pemanggilan SnackBar; pemeriksaan judul kosong dengan `trim()` dan `return` sudah ada sebelum commit itu. Status merge dikonfirmasi dari remote-tracking ref lokal `origin/develop`. Karena itu, pemeriksaan dilakukan terhadap diff, kode lokal, test, dan screenshot reproduksi, bukan ringkasan Copilot saja.

## Catatan

Minimal dua temuan AI harus diverifikasi benar dengan bukti, dan minimal satu temuan harus ditolak dengan alasan tertulis. Keputusan akhir tetap keputusan teknis author/reviewer, bukan keputusan AI.
