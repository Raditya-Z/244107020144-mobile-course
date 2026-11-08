# Praktikum 1 - Hygiene Branch dan Commit

## 1. Audit riwayat repository

Perintah audit yang digunakan pada repository proyek Minggu 5-7:

```bash
git log --oneline -15
git branch -a
git status
```

Hal yang diperiksa:

- Commit yang dibuat langsung ke `main`.
- Pesan commit yang terlalu umum, misalnya `fix bug` atau `update`.
- Branch yang berumur lebih dari satu minggu.
- File yang belum terlacak tetapi seharusnya di-commit, atau file yang seharusnya diabaikan.

## 2. Branch kerja

Branch fitur untuk perubahan praktikum ini:

```text
feat/notes-validation
```

Jika branch `develop` sudah tersedia, gunakan:

```bash
git checkout develop
git pull origin develop
git checkout -b feat/notes-validation
```

Jika `develop` belum tersedia, modul meminta membuatnya satu kali dari `main`, push, lalu membuat branch fitur:

```bash
git checkout main
git checkout -b develop
git push -u origin develop
git checkout -b feat/notes-validation
```

Perubahan di-stage secara interaktif dengan `git add -p`, supaya satu commit hanya memuat satu perubahan logis. Format commit contoh dari modul:

```bash
git add -p
git commit -m "feat(notes): validasi judul kosong + test"
git push -u origin feat/notes-validation
```

## 3. Simulasi perbaikan tiga pesan commit

Berikut tiga pesan lama dari riwayat repository dan usulan penulisannya kembali dalam format konvensional. Usulan disesuaikan dengan berkas yang berubah pada commit terkait.

| Pesan lama | Pesan perbaikan | Alasan |
|---|---|---|
| `add commit Praktikum 1` | `feat(auth): scaffold aplikasi Campus Notify dan alur autentikasi` | Menjelaskan bahwa commit menambahkan kerangka aplikasi Campus Notify beserta bagian autentikasi, bukan hanya menyebut nomor praktikum. |
| `add commit Praktikum 2` | `refactor(auth): pisahkan domain autentikasi dan penyimpanan token` | Menjelaskan perubahan struktur autentikasi dan pemindahan penyimpanan token ke susunan yang lebih terpisah. |
| `add commit Praktikum 3` | `feat(notes): tambahkan fitur catatan dengan clean architecture` | Menjelaskan fitur yang ditambahkan dan struktur yang dipakai: entity, repository, use case, database, serta halaman catatan. |

**Catatan:** bagian ini adalah simulasi penulisan ulang pesan lama beserta alasannya. Jangan mengubah riwayat commit lama untuk simulasi ini.

## Catatan modul

- Jangan mengerjakan perubahan langsung di `main`.
- Jika `develop` belum ada, buat dari `main` satu kali dan push.
- Setelah `develop` tersedia, jadikan branch itu target default PR dan jangan menyentuh `main` langsung.

---

# Praktikum 2 - PR dan Peer Review

## 1. Buka PR kecil

Buat PR dari `feat/notes-validation` ke `develop` dengan judul yang sesuai perubahan aktual:

```text
fix(notes): tampilkan pesan saat judul kosong
```

Deskripsi PR menjelaskan bahwa saat judul catatan kosong, UI menampilkan pesan `Judul tidak boleh kosong`. Jelaskan juga langkah uji manual yang benar-benar dilakukan. Jangan mengklaim use case atau file `test/validate_note_test.dart` karena file test tersebut tidak tersedia pada aplikasi Minggu 5.

## 2. Review sejawat selama 15 menit

Tukar PR dengan pasangan. Review mencakup:

- 2 temuan kebenaran, misalnya null, state, jalur error, atau edge case.
- 1 temuan arsitektur, misalnya import lintas layer, DI bocor, atau model bocor ke UI.
- 1 temuan test (kasus sukses/gagal yang kurang) dan 1 saran keterbacaan.
- Keputusan akhir: `Approve` atau `Request changes`.

## 3. Komentar review

Gunakan pola **observasi -> dampak -> usulan konkret**. Komentar yang diberikan untuk perubahan ini:

```text
Observasi: Belum ada test yang memeriksa perubahan saat judul catatan kosong.
Dampak: Perubahan bisa tidak menampilkan pesan error atau catatan kosong bisa tersimpan tanpa diketahui.
Usul: Tambahkan test yang memastikan judul kosong menampilkan pesan "Judul tidak boleh kosong" dan catatan tidak tersimpan.
Alasan: Test memastikan validasi tetap bekerja setelah kode diubah.
```

Catat tindak lanjut dan keputusan reviewer setelah proses review benar-benar dilakukan pada PR.

## 4. Tindak lanjut dan merge

Author memperbaiki temuan, meminta review ulang, lalu merge setelah disetujui. Gunakan squash bila commit perantara berantakan. Pastikan issue tertutup otomatis dan branch dihapus setelah merge.

---

# Praktikum 3 - Static Analysis dan Mid Review

## 1. Bersihkan dengan mesin

Pemeriksaan yang diminta modul:

```bash
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

### Status berdasarkan bukti yang tersedia

| Pemeriksaan | Status | Bukti/catatan |
|---|---|---|
| `flutter analyze` | Lulus | Terminal menampilkan `No issues found!`. |
| Format semua project dengan `dart format --set-exit-if-changed .` | Lulus | Setelah `flutter clean` dan `flutter pub get`, perintah melaporkan 16 file dan 0 perubahan. |
| `flutter test` | Lulus | Seluruh 6 test lulus, termasuk dua widget test validasi dan pembersihan SnackBar. |

Tindak lanjut AI verification: ditambahkan `test/notes_page_validation_test.dart` untuk kasus whitespace yang ditolak dan alur error-lalu-sukses. Perbaikan membersihkan SnackBar setelah save sukses. Hasil terkini: 6 test lulus, analyze bersih, dan formatter dengan target `.` menunjukkan 0 perubahan.

Ulangi pemeriksaan format setelah membersihkan hasil build. Jangan tandai format hijau sampai perintah pemeriksaan selesai tanpa perubahan atau error. Setelah format, ulangi analyze dan test.

## 2. Aktifkan penolakan otomatis (CI)

Workflow CI berada di `.github/workflows/ci.yml`. Karena repository berisi beberapa project, perintah CI diarahkan ke:

```text
05-week-5-local-storage-offline-first/week5_offline_notes
```

Workflow menjalankan `flutter analyze` dan `flutter test` saat pull request. Status GitHub Actions harus diperiksa setelah workflow di-commit dan di-push; keberhasilan belum dikonfirmasi dalam catatan ini.

## 3. Nilai kesiapan tengah semester

Lengkapi dan verifikasi hal-hal berikut sebelum menyatakan mid review selesai:

- Struktur feature-first dibuktikan dengan hasil tiga pemeriksaan Minggu 7.
- Analyze bersih, format lulus, dan test hijau.
- Minimal satu PR kecil per pasangan sudah di-merge setelah review.
- README mencantumkan status paruh semester, peta issue/PR, screenshot, dan cara menjalankan.
- Semua komentar reviewer sudah ditindaklanjuti.

## Definisi selesai dari modul

Mid review selesai bila aplikasi berjalan identik dengan akhir Minggu 7, tiga pemeriksaan mesin hijau, minimal satu PR kecil per pasangan sudah di-merge melalui review, dan README memuat status paruh semester serta peta issue/PR. Yang dinilai adalah fondasi yang dapat dipercaya untuk paruh kedua, bukan banyaknya fitur.

---
