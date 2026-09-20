# Verifikasi Hasil AI

Saya memeriksa kode awal yang dihasilkan GitHub Copilot berdasarkan checklist AI Challenge Week 4. Setelah menemukan beberapa bagian yang perlu disesuaikan, saya melakukan perbaikan dan menjalankan `flutter analyze` serta `flutter test` \

Salinan kode awal GitHub Copilot terdapat pada [output_ai.md](output_ai.md), sedangkan perubahan yang dilakukan dicatat pada [perbaikan.md](perbaikan.md).

## Checklist Verifikasi

| Checklist | Temuan Awal | Hasil Setelah Perbaikan |
| --- | --- | --- |
| UI tidak memanggil Dio langsung | Halaman memakai provider. Provider komentar memanggil repository. | Pola tersebut dipertahankan. Fitur komentar belum dihubungkan ke halaman. |
| `fromJson` aman null | Field hilang atau null mendapat nilai default. | Test JSON kosong dan semua field null lulus. Tipe data yang salah masih dapat menyebabkan cast error. |
| Timeout, `connectionError`, dan `badResponse` dipetakan ke pesan pengguna | Fungsi pesan sudah ada, tetapi belum ada test untuk error komentar. | Enam skenario error diuji, yaitu tiga timeout, `connectionError`, 404, dan 500. Semuanya menjadi `AsyncError` dan menghasilkan pesan yang sesuai. |
| Base URL dan timeout terpusat | Timeout ditulis kembali di repository. Provider post dan komentar juga membuat Dio sendiri. | Ketiga timeout dipusatkan di `api_client.dart`. Repository post dan komentar memakai provider Dio bersama. |
| Test field hilang dan edge case tambahan | Test dari Copilot baru menguji JSON kosong. | Ditambahkan test ketika semua field bernilai null. Kedua test berhasil. |
| `flutter analyze` dan `flutter test` | Sebelumnya tersedia laporan dari Copilot dan widget test masih berupa counter bawaan Flutter. | Widget test disesuaikan. Analyzer tidak menemukan issue dan seluruh 10 test berhasil. |

## Alur yang Saya Pahami

Alur pengambilan data komentar adalah:

```text
commentsProvider
      ↓
CommentRepository
      ↓
     Dio
      ↓
     API
```

`CommentRepository` bertugas melakukan request menggunakan Dio.

Model `Comment` digunakan untuk mengubah data JSON dari API menjadi objek yang dapat digunakan di aplikasi.

Provider mengatur state data seperti loading, berhasil, dan error.

UI nantinya membaca provider dan menggunakan `commentErrorMessage()` untuk menampilkan pesan ketika terjadi kegagalan.

Pada `CommentsNotifier`, method:

```dart
build()
```

meneruskan `Future` dari repository. Jika proses tersebut gagal, Riverpod dapat mengubah kegagalan tersebut menjadi `AsyncError`.

Sedangkan pada:

```dart
refresh()
```

digunakan:

```dart
AsyncValue.guard()
```

untuk menjalankan request kembali dan menangkap hasil berhasil maupun error.

Retry otomatis tetap dimatikan menggunakan:

```dart
retry: (retryCount, error) => null,
```

Pengujian yang dilakukan menunjukkan bahwa provider dapat mengalami kondisi error dan kemudian kembali menghasilkan data setelah proses refresh berhasil.

## Batas Hasil Verifikasi

Beberapa batas dari pengujian yang dilakukan adalah:

- Timeout 10 detik merupakan konfigurasi untuk koneksi, pengiriman, dan penerimaan data. Nilai tersebut bukan satu batas total untuk seluruh proses request.
- Test error menggunakan respons buatan sehingga tidak perlu menunggu koneksi internet benar-benar terputus atau server asli mengalami error.
- Jenis error Dio lainnya masih menggunakan pesan umum melalui bagian `default`. Pengujian difokuskan pada enam skenario utama yaitu `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, 404, dan 500.
- Halaman aplikasi masih menampilkan data post. Keberhasilan test provider komentar belum berarti pesan error komentar sudah berhasil ditampilkan pada UI.
- Hot restart belum dijalankan ulang setelah tahap perbaikan.

## Hasil Verifikasi

Setelah perbaikan, saya menjalankan:

```bash
flutter analyze
```

Hasil:

```text
Analyzing week4_api...

No issues found! (ran in 3.8s)
```

Kemudian saya menjalankan:

```bash
flutter test
```

Hasil:

```text
00:00 +10: All tests passed!
```

Dari hasil tersebut, kode sudah berhasil melewati analyzer dan seluruh test yang tersedia.

Namun, pengujian tampilan komentar pada UI belum dilakukan karena halaman aplikasi saat ini masih menampilkan post.

## Kesimpulan

Berdasarkan proses verifikasi, sebagian besar kode awal dari GitHub Copilot sudah sesuai dengan requirement AI Challenge Week 4.

Beberapa bagian masih perlu disesuaikan dengan project yang sudah ada, terutama pemusatan konfigurasi timeout, penggunaan provider Dio bersama, penambahan edge case, dan penyesuaian widget test.

Setelah perbaikan dilakukan, `flutter analyze` tidak menemukan issue dan seluruh 10 test berhasil dijalankan menggunakan `flutter test`.