# Week 8 — Mid Project Review

Folder ini merangkum kelanjutan proyek portfolio Minggu 5–7 untuk mid-project review. Proyek yang dilanjutkan adalah aplikasi **Offline Notes** dari Minggu 5; aplikasi baru tidak dibuat.

## Ringkasan proyek

- **Aplikasi:** Offline Notes, aplikasi Flutter untuk membuat dan mengelola catatan secara lokal serta menampilkan status sinkronisasi.
- **Perubahan utama:** validasi judul catatan kosong menampilkan pesan `Judul tidak boleh kosong`; setelah penyimpanan berhasil, pesan validasi dibersihkan.
- **Branch fitur:** `feat/notes-validation`.
- **Target perubahan:** `develop`.
- **Branch dokumentasi dan tindak lanjut:** `feature/week8-ai-verification`.
- **Issue:** [#3 — Validasi judul kosong pada catatan](https://github.com/Raditya-Z/244107020144-mobile-course/issues/3), ditutup sebagai **completed** setelah perbaikan pada PR #1 dan #2.

## Status tugas dan review

| Kriteria | Status | Bukti/catatan |
|---|---|---|
| Melanjutkan proyek Minggu 5–7 | Selesai | Perubahan dilakukan pada aplikasi Offline Notes Minggu 5. |
| Minimal satu PR kecil di-merge | Selesai | PR #1 dari `feat/notes-validation` ke `develop` tercatat merged; merge commit lokal `06ec524`. |
| PR dilengkapi masalah, solusi, cara uji, dan screenshot | Sebagian | Template dan bukti PR tersimpan di screenshot. Pastikan isi/tautan PR dapat dilihat pada GitHub. |
| `flutter analyze` | Lulus | `No issues found!` pada pemeriksaan terakhir. |
| `flutter test` | Lulus | 6 test lulus pada pemeriksaan terakhir. |
| `dart format --set-exit-if-changed .` | Lulus | 16 file diperiksa, 0 file berubah. |
| CI GitHub Actions | Lulus | `ci #1` berhasil pada PR #2, branch `feature/week8-ai-verification`. Workflow berisi format, analyze, dan test. |
| AI review dan verifikasi | Terdokumentasi | Prompt, temuan, bukti, dan keputusan ada di [`docs/ai-review-vs-keputusan.md`](docs/ai-review-vs-keputusan.md). |

## Stack teknologi

Stack aplikasi Offline Notes berdasarkan konfigurasi project:

- **Flutter dan Dart** untuk aplikasi.
- **Riverpod** (`flutter_riverpod`) untuk pengelolaan state.
- **GoRouter** (`go_router`) untuk navigasi.
- **SQLite** melalui `sqflite` untuk penyimpanan lokal.
- **Dio** untuk permintaan HTTP/sinkronisasi.
- **SharedPreferences** untuk preferensi sederhana.

## Cara menjalankan aplikasi

Dari root repository, jalankan:

```powershell
cd 05-week-5-local-storage-offline-first/week5_offline_notes
flutter pub get
flutter run
```

Untuk menjalankan pemeriksaan mesin dari folder aplikasi yang sama:

```powershell
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Workflow CI di `.github/workflows/ci.yml` menjalankan pemeriksaan format, analyze, dan test pada pull request. Hasil lokal terakhir lulus. GitHub Actions juga menunjukkan `ci #1` berhasil untuk PR #2 dari branch `feature/week8-ai-verification` (bukti pada tangkapan layar yang diberikan).

### Proyek Minggu 7

Aplikasi Clean Architecture Minggu 7 berada di `07-week-7-clean-architecture`. Jalankan dari root repository:

```powershell
cd 07-week-7-clean-architecture
flutter pub get
flutter run
```

Lihat [README aplikasi Minggu 7](../07-week-7-clean-architecture/README.md) untuk konfigurasi khusus dan penjelasan proyek tersebut.

## Peta issue, branch, dan PR

| Item | Status | Catatan |
|---|---|---|
| PR #1: validasi judul kosong | Merged | Source `feat/notes-validation`, target `develop`. |
| PR #2: tindak lanjut Week 8 | Merged; CI lulus | PR #2 `fix(notes): clear validation snackbar after save` sudah merged dan check `ci` lulus (1/1). Source `feature/week8-ai-verification`. |
| [Issue #3: Validasi judul kosong pada catatan](https://github.com/Raditya-Z/244107020144-mobile-course/issues/3) | Closed | Ditutup sebagai completed dengan komentar yang merujuk perbaikan di PR #1 dan #2. Penutupan dilakukan manual setelah PR di-merge. |


## Hasil uji dan bukti

Test widget validasi berada di `05-week-5-local-storage-offline-first/week5_offline_notes/test/notes_page_validation_test.dart`.

Pemeriksaan terakhir pada aplikasi Minggu 5:

| Perintah | Hasil |
|---|---|
| `dart format --set-exit-if-changed .` | Lulus — 16 file, 0 perubahan. |
| `flutter analyze` | Lulus — tidak ada masalah. |
| `flutter test` | Lulus — 6 test. |

Screenshot proses dan hasil:

- [Audit riwayat Git](screenshots/Audit%20riwayat.png)
- [Pembuatan branch kerja — bagian 1](screenshots/Buat%20Branch%20Kerja%201.png) dan [bagian 2](screenshots/Buat%20Branch%20Kerja%202.png)
- [PR kecil](screenshots/Buka%20PR%20kecil.png)
- [Pemeriksaan dengan mesin](screenshots/Bersihkan%20dengan%20mesin.png)
- [Workflow CI](screenshots/Aktifkan%20penolakan%20otomatis%20%28CI%29.png)
- [Tindak lanjut dan merge](screenshots/Tindak%20lanjut%20dan%20merge.png)
- [Validasi ketika dialog terbuka](screenshots/Manual-validasi-dialog-terbuka.jpg)
- [Pesan setelah penyimpanan berhasil](screenshots/Manual-validasi-setelah-simpan.jpg)
- [Home Minggu 7 sebelum perubahan](../07-week-7-clean-architecture/screenshots/HasilPraktikum-HomeBefore.jpg)
- [Home Minggu 7 setelah perubahan](../07-week-7-clean-architecture/screenshots/HasilPraktikum-HomeAfter.jpeg)

Dokumen pendukung Week 8:

- [Checklist review](docs/review-checklist.md)
- [Prompt AI, temuan, bukti, dan keputusan akhir](docs/ai-review-vs-keputusan.md)
- [Screenshot](screenshots/)

## Refleksi

### Perbedaan LGTM dan Approve yang bertanggung jawab

LGTM menyampaikan bahwa perubahan terlihat baik secara umum. Approve adalah keputusan review yang menyatakan perubahan sudah diperiksa cukup teliti untuk digabungkan, termasuk perilaku, risiko, pengujian, dan dampak arsitekturnya. Approve tanpa memeriksa perubahan dan bukti uji dapat membiarkan regresi masuk ke branch bersama.

### Kapan komentar menjadi Request changes

Request changes layak digunakan jika ada masalah yang harus diperbaiki sebelum merge, misalnya perilaku salah, kasus penting belum ditangani, test gagal/tidak mencakup risiko utama, atau perubahan melanggar batas arsitektur. Saran yang tidak menghalangi fungsi dan keamanan dapat disampaikan sebagai komentar biasa.

### Keputusan terhadap review AI

Temuan AI saya periksa terhadap kode dan bukti test, lalu keputusan menerima, menyederhanakan, atau menolak beserta alasannya dicatat di [`docs/ai-review-vs-keputusan.md`](docs/ai-review-vs-keputusan.md). Hasil AI tidak diterapkan otomatis. Review AI juga tidak dianggap sebagai review sejawat manusia.

### Perbaikan konkret dan dampaknya

Saya memperbaiki alur validasi judul kosong dan memastikan pesan validasi dibersihkan setelah catatan berhasil disimpan. Dampaknya, pengguna memperoleh umpan balik ketika judul kosong dan tidak terus melihat pesan lama setelah penyimpanan sukses. Perubahan ini dibuktikan dengan widget test serta pemeriksaan manual yang screenshot-nya tersedia di folder `screenshots/`.

## Referensi

- Materi kuliah **Week 8: Mid Project Review & Code Review** yang diberikan pada modul.
- [Atlassian: Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [GitHub: About pull request reviews](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [Flutter: Static analysis](https://docs.flutter.dev/tools/analysis)
- [Dart: Linter rules](https://dart.dev/tools/linter-rules)
- [GitHub Actions: Workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions)
- [Learn Dart in Y Minutes](https://learnxinyminutes.com/docs/dart/)

