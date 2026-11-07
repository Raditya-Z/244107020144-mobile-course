# Week 8 - Mid Project Review

Dokumen ini merangkum review tengah semester untuk aplikasi Flutter yang dikembangkan pada minggu 5-7. Praktikum 1-3 dan bukti terminal tersimpan di folder ini.

## Status review

- **Branch PR:** `feat/notes-validation`
- **Target PR:** `develop`
- **Perubahan yang direview:** menampilkan pesan `Judul tidak boleh kosong` saat pengguna mencoba menyimpan catatan tanpa judul.
- **Static analysis:** lulus pada hasil terminal yang tersedia (`No issues found!`).
- **Automated test:** 6 test lulus, termasuk widget test validasi judul kosong dan pembersihan pesan setelah simpan sukses.
- **Format:** setelah `flutter clean` dan `flutter pub get`, `dart format --set-exit-if-changed .` lulus dan melaporkan 16 file, 0 perubahan.
- **CI GitHub Actions:** workflow disiapkan di `.github/workflows/ci.yml`; status run pada GitHub perlu diperiksa setelah workflow di-push.
- **PR #1:** merged ke `develop` (merge commit lokal `06ec524`).
- **Follow-up:** branch lokal `feature/week8-ai-verification` berisi pembersihan SnackBar setelah simpan sukses, widget test, CI, dan dokumentasi week 8. PR follow-up belum dibuat.

## Struktur project dan cara menjalankan

### Aplikasi catatan Minggu 5 (perubahan pada PR)

Dari root repository:

```powershell
cd 05-week-5-local-storage-offline-first/week5_offline_notes
flutter pub get
flutter run
```

Pemeriksaan lokal dari folder aplikasi yang sama:

```powershell
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

### Aplikasi Clean Architecture Minggu 7

Aplikasi Minggu 7 berada di `07-week-7-clean-architecture`. Untuk menjalankannya:

```powershell
cd 07-week-7-clean-architecture
flutter pub get
flutter run
```

Struktur feature-first dan hasil verifikasi Minggu 7 dijelaskan lebih lengkap pada [README aplikasi Minggu 7](../07-week-7-clean-architecture/README.md). Ikuti instruksi konfigurasi yang tercantum di README tersebut jika aplikasi memerlukan layanan eksternal.

## Peta issue dan PR

| Item | Status | Catatan |
|---|---|---|
| PR validasi catatan #1 | Merged | Source `feat/notes-validation`, target `develop`. |
| PR follow-up | Belum dibuat | Branch `feature/week8-ai-verification`; berisi perbaikan SnackBar, widget test, CI, dan dokumen verifikasi. |
| Issue terkait | Belum dicatat | Isi nomor dan tautan hanya jika issue benar-benar dibuat. |
| Komentar review | Perlu ditindaklanjuti | Reviewer meminta test untuk judul kosong; catat hasil setelah diperbaiki dan direview ulang. |
| Merge | Belum dikonfirmasi | Isi setelah PR disetujui dan merge ke `develop`. |

## Bukti screenshot

Screenshot terminal dan alur Git untuk Praktikum 1-3 tersedia di [`screenshots/`](screenshots/):

- [Audit riwayat](screenshots/Audit%20riwayat.png)
- [Pembuatan branch kerja](screenshots/Buat%20Branch%20Kerja%201.png) dan [lanjutan branch](screenshots/Buat%20Branch%20Kerja%202.png)
- [Buka PR kecil](screenshots/Buka%20PR%20kecil.png)
- [Bersihkan dengan mesin](screenshots/Bersihkan%20dengan%20mesin.png)
- [Aktifkan CI](screenshots/Aktifkan%20penolakan%20otomatis%20(CI).png)
- [Tindak lanjut dan merge](screenshots/Tindak%20lanjut%20dan%20merge.png)
- [Validasi kosong saat dialog terbuka](screenshots/Manual-validasi-dialog-terbuka.jpg)
- [SnackBar setelah catatan berhasil disimpan](screenshots/Manual-validasi-setelah-simpan.jpg)

Test widget validasi disimpan di `05-week-5-local-storage-offline-first/week5_offline_notes/test/notes_page_validation_test.dart`. Hasil pemeriksaan terakhir: `flutter analyze` bersih; `flutter test` lulus (6 test); `dart format --set-exit-if-changed .` menunjukkan 0 perubahan dari 16 file.

Screenshot aplikasi Minggu 7:

- [Home sebelum perubahan](../07-week-7-clean-architecture/screenshots/HasilPraktikum-HomeBefore.jpg)
- [Home setelah perubahan](../07-week-7-clean-architecture/screenshots/HasilPraktikum-HomeAfter.jpeg)

## Catatan penyelesaian

Jangan tandai mid review selesai sebelum hasil format dan CI telah dikonfirmasi, semua komentar reviewer ditindaklanjuti, serta minimal satu PR kecil per pasangan benar-benar di-merge melalui review.
