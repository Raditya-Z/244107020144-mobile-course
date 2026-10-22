# Verifikasi Dependency Rule dan Proyek

## 1. Pemeriksaan Dependency Rule

Pemeriksaan ini dilakukan untuk memastikan pemisahan tanggung jawab antara presentation, domain, dan data sudah sesuai dengan prinsip Clean Architecture.

| Pemeriksaan | Hasil dan Arti | Status |
|---|---|---|
| Presentation tidak mengakses Dio, database, secure storage, SharedPreferences, atau parsing JSON secara langsung | Pemeriksaan sebelumnya tidak menemukan kecocokan pada pola dan direktori yang diperiksa. Namun, cakupan pencarian belum memastikan seluruh file presentation sudah diperiksa. | Perlu diverifikasi |
| Domain tidak mengimpor Flutter, Dio, SQLite, atau Firebase | Pemeriksaan sebelumnya tidak menemukan kecocokan. Karena pencarian menggunakan pola direktori tertentu, hasil tersebut belum cukup untuk memastikan seluruh domain dan core bebas dari import yang dilarang. | Perlu diverifikasi |
| Repository interface dan implementasi berada di layer yang sesuai | Dari file yang diperiksa, kontrak repository berada di `features/notes/domain/repositories/note_repository.dart`, sedangkan implementasinya berada di `features/notes/data/repositories/note_repository_impl.dart`. Pasangan repository auth juga ditemukan pada folder domain dan data. | Lulus untuk file yang diperiksa |
| Dependency injection menggunakan provider Riverpod | Provider notes menghubungkan repository dan use case. Provider auth juga menghubungkan dependency yang dibutuhkan. Namun, seluruh wiring belum diverifikasi. | Perlu diverifikasi |
| Pemeriksaan akses data mentah pada seluruh file Dart | Belum ada hasil pemindaian menyeluruh yang tercatat. Pemeriksaan ini diperlukan untuk memastikan tidak ada akses langsung ke layanan eksternal pada presentation. | Belum dijalankan |

### Perintah pemeriksaan Presentation

```powershell
Get-ChildItem lib -Recurse -File -Filter *.dart |
Select-String -Pattern 'Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode'
```

Periksa setiap hasil berdasarkan lokasi file dan tanggung jawabnya. Tidak semua hasil otomatis merupakan pelanggaran jika pemanggilan tersebut berada pada layer data yang memang bertanggung jawab mengakses sumber data.

### Perintah pemeriksaan Domain

```powershell
Get-ChildItem lib -Recurse -File -Filter *.dart |
Where-Object { $_.FullName -match '\\domain\\|\\core\\' } |
Select-String -Pattern "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase"
```

Jika ditemukan hasil, periksa apakah file tersebut benar-benar berada di domain atau core dan apakah import tersebut melanggar aturan dependency.

## 2. Validasi Proyek

| Pemeriksaan | Perintah | Hasil | Status |
|---|---|---|---|
| Static analysis | `flutter analyze -v` | `No issues found! (ran in 4.4s)` | Lulus |
| Automated tests | `flutter test --reporter expanded` | `All tests passed!` dengan 6 test berhasil | Lulus |

### Hasil Static Analysis

Saya menjalankan perintah `flutter analyze -v` untuk memeriksa kemungkinan masalah pada kode Dart. Hasilnya menunjukkan `No issues found!`, sehingga tidak ditemukan masalah oleh static analyzer pada saat pemeriksaan dilakukan.

### Hasil Automated Tests

Saya menjalankan perintah `flutter test --reporter expanded`. Hasilnya menunjukkan enam test berhasil, yaitu:

1. `routeFromMessage` menangani route kosong dan tanpa slash.
2. `routeFromMessage` membawa ID pengumuman dari payload.
3. Provider auth membaca status login dari token.
4. Kegagalan refresh auth menyebabkan sesi dibersihkan.
5. Error API dengan status 401 menghasilkan pesan sesi berakhir.
6. Error API akibat timeout menghasilkan pesan koneksi timeout.

Hasil tersebut menunjukkan bahwa seluruh test yang tersedia pada eksekusi ini berhasil. Namun, test tersebut belum membuktikan bahwa skenario sukses dan failure domain menggunakan fake repository sudah diuji.

## 3. Kesimpulan

Berdasarkan hasil pemeriksaan terbaru, `flutter analyze` dan `flutter test` berhasil dijalankan tanpa masalah yang dilaporkan. Pemisahan kontrak dan implementasi repository juga sudah sesuai pada file yang diperiksa.

Namun, pemeriksaan menyeluruh terhadap dependency rule masih perlu dilakukan. Saya juga perlu memastikan bahwa pengujian domain menggunakan fake repository tersedia jika ingin memenuhi seluruh checklist praktikum.