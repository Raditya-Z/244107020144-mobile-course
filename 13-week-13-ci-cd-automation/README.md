# Week 13 — CI/CD & Otomatisasi

Folder ini berisi aplikasi `campus_notify` (kelanjutan Minggu 12) beserta pipeline
CI/CD GitHub Actions sesuai modul
[13 - CI/CD dan Otomatisasi](https://jti-polinema.github.io/flutter-codelab/13-minggu-13-ci-cd-automation/index.html).

## Pipeline

Workflow `flutter-ci.yml` menjalankan langkah berikut secara berurutan pada runner
`ubuntu-latest`; kegagalan di satu langkah menghentikan job sehingga artefak tidak
diunggah.

| # | Langkah | Perintah | Gagal bila |
| --- | --- | --- | --- |
| 1 | Ambil source | `actions/checkout@v4` | checkout gagal |
| 2 | Siapkan Flutter | `subosito/flutter-action@v2` (`channel: stable`) | SDK gagal dipasang |
| 3 | Dependensi | `flutter pub get` | resolusi paket gagal |
| 4 | Format | `dart format --output=none --set-exit-if-changed .` | ada file tidak terformat |
| 5 | Analisis statis | `flutter analyze --fatal-infos` | ada error, warning, atau info |
| 6 | Test + cakupan | `flutter test --coverage` | ada test gagal |
| 7 | Build APK | `flutter build apk --release` | kompilasi/signing debug gagal |
| 8 | Build AAB | `flutter build appbundle --release` | kompilasi/signing debug gagal |
| 9 | Simpan artefak | `actions/upload-artifact@v4` | file APK/AAB tidak ditemukan |

## Lokasi workflow

Repository ini berisi satu folder per minggu, sedangkan GitHub hanya membaca
workflow dari `.github/workflows/` di root repository. Karena itu workflow berada di
[`.github/workflows/flutter-ci.yml`](../.github/workflows/flutter-ci.yml) dengan
`defaults.run.working-directory: 13-week-13-ci-cd-automation`, bukan di dalam folder
minggu. Path artefak ikut ditulis lengkap dari root karena `working-directory` hanya
berlaku untuk langkah `run`, bukan untuk `uses`.

Workflow lama `.github/workflows/ci.yml` tetap dipakai sebagai gerbang pull request
minggu sebelumnya dan tidak diubah.

## Event, permission, dan concurrency

- `push` dan `pull_request` ke `main` dan `develop`. Branch utama repository adalah
  `main`; `develop` ditambahkan karena alur kerja repository memakai `develop`
  sebagai branch integrasi, sehingga pemeriksaan yang sama juga berjalan saat pull
  request ke `develop`.
- `workflow_dispatch` untuk menjalankan ulang pipeline secara manual.
- `permissions: contents: read` — job hanya membaca kode; tidak ada izin tulis.
- `concurrency` per workflow + ref dengan `cancel-in-progress: true`, sehingga push
  baru membatalkan run lama pada branch yang sama dan tidak menumpuk build.

## Artefak

| Artefak | Path | Keterangan |
| --- | --- | --- |
| APK | `build/app/outputs/flutter-apk/app-release.apk` | Instalasi/uji internal |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | Format distribusi Google Play |

Keduanya diunggah sebagai artefak `android-builds` dengan `retention-days: 7` dan
`if-no-files-found: error` agar job gagal bila build tidak benar-benar menghasilkan
file. Artefak dapat diunduh dari halaman run di tab **Actions**.

## Konfigurasi Firebase di CI

`android/app/google-services.json` diabaikan Git (lihat `.gitignore`) karena berisi
konfigurasi Firebase lokal, termasuk API key klien. Runner CI tidak memiliki file
itu, sehingga `android/app/build.gradle.kts` menerapkan plugin
`com.google.gms.google-services` hanya jika file tersebut ada:

```kotlin
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
```

Kedua jalur sudah diuji lokal: build sukses tanpa file (menyerupai kondisi CI) dan
dengan file (mesin lokal). Konsekuensinya, artefak dari CI tidak membawa konfigurasi
Firebase sehingga fitur notifikasi tidak aktif di APK/AAB hasil pipeline; untuk
rilis nyata, konfigurasi harus diinjeksikan dari secret pada workflow rilis yang
dibatasi.

## Versioning

| Item | Sebelum | Sesudah | Alasan |
| --- | --- | --- | --- |
| `version` di `pubspec.yaml` | `1.0.0+1` | `1.1.0+2` | Minor: fitur pencarian judul catatan dan integrasi AI sudah masuk sejak Minggu 9–11; build number naik satu untuk artefak baru |

Rencana tag rilis berikutnya: `v1.1.0`, dibuat pada commit yang sudah lolos
workflow di branch utama. Tag menghubungkan source, log pipeline, dan artefak APK/AAB
pada satu titik. Setiap unggahan baru wajib menaikkan build number (`+3`, `+4`, …)
meskipun versi aplikasi tidak berubah.

## Menjalankan pemeriksaan yang sama secara lokal

```bash
cd 13-week-13-ci-cd-automation
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --release
flutter build appbundle --release
```

Di CI, `dart format .` dijalankan dari folder minggu (checkout bersih tanpa `build/`),
sedangkan di lokal perintah dibatasi ke `lib test integration_test` karena folder
`build/` berisi path panjang yang membuat formatter gagal.

## Hasil pemeriksaan lokal

Dijalankan pada Flutter 3.47.6 / Dart 3.13.5, Windows.

| Pemeriksaan | Hasil |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 63 file, 0 berubah |
| `flutter analyze --fatal-infos` | No issues found! |
| `flutter test --coverage` | **+60: All tests passed!** |
| `flutter build apk --release` | BUILD SUCCESSFUL — `app-release.apk` (52,3 MB) |
| `flutter build appbundle --release` | BUILD SUCCESSFUL — `app-release.aab` (51,5 MB) |
| `flutter build apk --release` tanpa `google-services.json` | BUILD SUCCESSFUL — plugin Firebase dilewati (simulasi kondisi CI) |

## Bukti di GitHub Actions

Workflow berjalan otomatis pada push/pull request ke `main` atau `develop` setelah
workflow ini di-merge, atau lewat **Run workflow** (`workflow_dispatch`). Untuk
setiap run, catat:

- nomor run dan commit SHA yang memicunya (halaman run menampilkan keduanya);
- status tiap step (format, analyze, test, build APK, build AAB, upload artefak);
- nama artefak `android-builds` beserta ukuran APK/AAB yang diunduh.

Tangkapan layar halaman run dan daftar artefak disimpan di folder ini setelah run
pertama tersedia.

## Risiko keamanan yang masih perlu ditangani

1. **Release masih ditandatangani debug key.** `android/app/build.gradle.kts` memakai
   `signingConfigs.getByName("debug")`, jadi APK/AAB hanya layak untuk uji internal.
   Keystore produksi belum ada; bila nanti dibuat, material signing harus disimpan di
   GitHub Actions Secrets dan hanya diinjeksi pada workflow rilis yang dibatasi
   (bukan pada pull request).
2. **Artefak CI tanpa konfigurasi Firebase.** `google-services.json` berisi API key
   proyek, jadi file itu tetap diabaikan Git dan plugin Firebase dilewati saat file
   tidak ada. APK/AAB dari pipeline karena itu tidak memuat konfigurasi Firebase;
   untuk rilis nyata, injeksikan file dari secret pada workflow rilis yang dibatasi
   dan jangan pernah mencetak isinya ke log.
3. **`--dart-define` bukan tempat menyimpan secret.** Nilai yang dikompilasi dapat
   diekstrak dari aplikasi klien. API key AI saat ini diisi pengguna dan disimpan di
   secure storage perangkat, tidak ditanam ke build; praktik itu harus dipertahankan.
4. **Pull request dari fork tidak mendapat akses Secrets.** Rilis bertanda tangan
   resmi tidak boleh bergantung pada workflow yang dapat dijalankan dari fork; batasi
   job rilis ke branch/tag terlindungi.
5. **Artefak dapat diunduh kolaborator.** APK/AAB (walau dengan debug key) tersimpan
   7 hari; jangan mengunggah build yang berisi data atau konfigurasi sensitif.
6. **Integration test tidak berjalan di CI.** Alur SQLite di perangkat hanya
   terverifikasi lokal; pipeline belum menyediakan emulator.
7. **Action belum dipin ke commit SHA.** `actions/checkout@v4`,
   `actions/upload-artifact@v4`, dan `subosito/flutter-action@v2` memakai tag major;
   untuk rantai pasok yang lebih ketat, pin ke SHA tertentu.

## Refleksi

**Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?**

Format dan analisis dengan `--fatal-infos`: satu baris tidak terformat atau satu
`info` (misalnya import tidak terpakai) langsung menggagalkan job, sesuatu yang mudah
terlewat saat review manual. Test juga mengunci perilaku Minggu 12 (validasi judul,
pesan error, pencarian) sehingga regresi terdeteksi sebelum merge, dan build release
membuktikan `google-services.json` serta signing debug masih lengkap.

**Informasi apa yang Anda butuhkan untuk menyelidiki build yang gagal?**

Commit SHA dan branch pemicu, nama step yang gagal, log lengkap step tersebut, versi
Flutter/SDK yang dipakai runner, serta apakah artefak terunggah. Log lokal saja tidak
cukup karena lingkungan runner berbeda; `workflow_dispatch` memudahkan reproduksi
pada commit yang sama.

**Bagian mana yang masih perlu persetujuan atau pemeriksaan manual sebelum rilis?**

Signing dengan keystore produksi, peninjauan izin dan konfigurasi aplikasi,
pengujian di perangkat nyata (termasuk integration test), penomoran versi/build, dan
pembuatan tag `v1.1.0` pada commit yang sudah lolos pipeline. Build sukses di CI
tidak otomatis berarti siap dipublikasikan.

## Catatan penggunaan AI

Workflow, README, dan analisis risiko disusun dengan bantuan AI, lalu setiap langkah
dijalankan ulang secara lokal (`pub get`, format, analyze, test, build APK/AAB)
sebelum dianggap selesai. Tidak ada token, password, atau keystore yang disimpan di
repository.
