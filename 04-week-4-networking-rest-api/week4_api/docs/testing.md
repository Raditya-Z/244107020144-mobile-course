# Hasil Testing

Setelah kode dari GitHub Copilot diverifikasi dan diperbaiki, saya melakukan pengujian menggunakan `flutter analyze` dan `flutter test`

Tujuan pengujian ini adalah untuk memeriksa apakah kode lolos analyzer, model dapat menangani data yang tidak lengkap, serta provider dapat menangani error dan mengambil data kembali melalui refresh.

## 1. Flutter Analyze

Perintah yang digunakan:

```bash
flutter analyze
```

Perintah tersebut digunakan untuk memeriksa apakah terdapat masalah pada kode Flutter, seperti error, warning, atau masalah lain yang dapat dideteksi oleh analyzer.

### Hasil Setelah Perbaikan

```text
Analyzing week4_api...

No issues found! (ran in 3.8s)
```

Hasil tersebut menunjukkan bahwa tidak ada issue yang ditemukan oleh analyzer setelah perbaikan dilakukan.

Perubahan kode yang dilakukan sebelumnya dijelaskan pada [perbaikan.md](perbaikan.md).

---

## 2. Unit Test Model Comment

Model yang diuji berada pada:

```text
lib/data/models/comment.dart
```

Sedangkan test berada pada:

```text
test/comment_test.dart
```

### Test Field Hilang

Test awal dari GitHub Copilot menggunakan JSON kosong:

```dart
final comment = Comment.fromJson({});

expect(comment.postId, 0);
expect(comment.id, 0);
expect(comment.name, '');
expect(comment.email, '');
expect(comment.body, '');
```

Test ini digunakan untuk memastikan bahwa field yang tidak tersedia akan diganti dengan nilai default.

Untuk field angka digunakan nilai:

```text
0
```

Sedangkan untuk field String digunakan:

```text
''
```

Dengan demikian, model tetap dapat dibuat ketika field pada JSON tidak tersedia.

### Test Tambahan: Semua Field Null

Saya menambahkan satu edge case ketika seluruh field tersedia tetapi memiliki nilai `null`:

```dart
final comment = Comment.fromJson({
  'postId': null,
  'id': null,
  'name': null,
  'email': null,
  'body': null,
});

expect(comment.toJson(), {
  'postId': 0,
  'id': 0,
  'name': '',
  'email': '',
  'body': '',
});
```

Test tersebut memastikan nilai `null` juga menggunakan nilai default.

Kedua test berhasil dijalankan.

Pengujian ini membuktikan penanganan terhadap field hilang dan field bernilai null. Namun, test belum memeriksa tipe data yang salah, misalnya field `name` berisi angka.

---

## 3. Pengujian Error pada Provider Komentar

Pengujian error terdapat pada:

```text
test/comment_provider_test.dart
```

Pengujian menggunakan interceptor Dio untuk memberikan respons buatan. Dengan cara ini, test tidak bergantung pada koneksi internet maupun kondisi server JSONPlaceholder.

Enam kondisi error yang diuji adalah:

| Kondisi | Pesan yang Diharapkan |
| --- | --- |
| `connectionTimeout` | Koneksi timeout. Periksa internet Anda lalu coba lagi. |
| `sendTimeout` | Koneksi timeout. Periksa internet Anda lalu coba lagi. |
| `receiveTimeout` | Koneksi timeout. Periksa internet Anda lalu coba lagi. |
| `connectionError` | Tidak dapat terhubung ke server. Periksa internet Anda. |
| `badResponse` dengan status 404 | Komentar tidak ditemukan (404). |
| `badResponse` dengan status 500 | Server sedang bermasalah (500). Coba lagi nanti. |

### Pemeriksaan Kondisi Gagal

Test menunggu proses asynchronous menggunakan:

```dart
await expectLater(
  container.read(provider.future),
  throwsA(isA<DioException>()),
);
```

Setelah Future menghasilkan error, state provider dan pesan error diperiksa:

```dart
final failed = container.read(provider);

expect(failed.hasError, isTrue);
expect(commentErrorMessage(failed.error!), message);
expect(calls, 1);
```

Variabel `message` berisi pesan yang diharapkan untuk setiap skenario error.

Variabel `calls` digunakan untuk menghitung jumlah request yang diterima interceptor.

Nilai:

```text
calls = 1
```

menunjukkan bahwa baru terdapat satu request sampai tahap pemeriksaan error.

Retry otomatis pada provider sudah dimatikan menggunakan:

```dart
retry: (retryCount, error) => null,
```

Pengaturan tersebut dipertahankan agar error dapat langsung diperiksa tanpa adanya request ulang otomatis.

### Pemeriksaan Request dan Timeout

Pada setiap skenario, test juga memeriksa konfigurasi request:

```dart
expect(options.path, '/comments');
expect(options.queryParameters['postId'], 7);
expect(
  options.baseUrl,
  'https://jsonplaceholder.typicode.com',
);
expect(
  options.connectTimeout,
  const Duration(seconds: 10),
);
expect(
  options.sendTimeout,
  const Duration(seconds: 10),
);
expect(
  options.receiveTimeout,
  const Duration(seconds: 10),
);
```

Pemeriksaan tersebut memastikan bahwa:

- Request menuju endpoint `/comments`.
- `postId` dikirim dengan nilai yang benar.
- Base URL menggunakan JSONPlaceholder.
- `connectTimeout` bernilai 10 detik.
- `sendTimeout` bernilai 10 detik.
- `receiveTimeout` bernilai 10 detik.

Test hanya memeriksa nilai konfigurasi timeout. Test tidak benar-benar menunggu jaringan selama 10 detik.

---

## 4. Pengujian Refresh Setelah Error

Pada masing-masing dari enam skenario error, respons buatan kemudian diubah menjadi respons berhasil.

Test selanjutnya menjalankan:

```dart
shouldFail = false;

await container.read(provider.notifier).refresh();

expect(
  states.any((state) => state.isLoading),
  isTrue,
);

final comments = container.read(provider).requireValue;

expect(comments.single.postId, 7);
expect(comments.single.body, 'Isi');
expect(calls, 2);
```

Setelah `refresh()` dijalankan, provider berhasil menghasilkan data komentar walaupun sebelumnya berada dalam kondisi error.

Test juga memeriksa bahwa terdapat state loading selama proses pengujian.

Jumlah request kemudian menjadi:

```text
calls = 2
```

Jumlah tersebut berasal dari:

```text
Request 1 → gagal
Request 2 → refresh berhasil
```

Selain itu, terdapat satu test tambahan untuk memastikan:

```text
commentDioProvider
```

dan:

```text
dioProvider
```

mengembalikan instance Dio yang sama dalam satu container Riverpod.

Test tersebut berhasil, sehingga provider komentar sudah menggunakan client Dio bersama.

---

## 5. Perbaikan dan Pengujian Widget

Saat memeriksa kode awal, file:

```text
test/widget_test.dart
```

masih berisi test counter bawaan Flutter.

Test tersebut mencari angka `0`, angka `1`, dan tombol tambah. Test tersebut sudah tidak sesuai karena aplikasi Week 4 sekarang menampilkan halaman post.

Widget test kemudian disesuaikan dan aplikasi dibungkus menggunakan `ProviderScope`:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      postRepositoryProvider.overrideWithValue(
        FakePostRepository(dio),
      ),
    ],
    child: const MyApp(),
  ),
);

await tester.pumpAndSettle();
```

`FakePostRepository` memberikan data lokal sehingga widget test tidak perlu melakukan request melalui internet.

`pumpAndSettle()` digunakan untuk menunggu proses perubahan tampilan selesai sebelum hasilnya diperiksa.

Pemeriksaan widget dilakukan menggunakan:

```dart
expect(find.text('Posts Paged'), findsOneWidget);
expect(find.text('Post pengujian'), findsOneWidget);
expect(find.text('Semua data termuat.'), findsOneWidget);
expect(tester.takeException(), isNull);
```

Test tersebut berhasil.

Hasil ini menunjukkan bahwa halaman post dapat menampilkan data dari repository buatan tanpa exception yang tertangkap selama widget test.

---

## 6. Hasil Akhir Flutter Test

Setelah seluruh perbaikan dilakukan, saya menjalankan:

```bash
flutter test
```

Hasil akhirnya:

```text
00:00 +10: All tests passed!
```

Sepuluh test yang berhasil terdiri dari:

| Jenis Pengujian | Jumlah |
| --- | ---: |
| Model dengan JSON kosong | 1 |
| Model dengan semua field null | 1 |
| Error provider dan refresh: tiga timeout, `connectionError`, 404, dan 500 | 6 |
| Instance Dio bersama | 1 |
| Widget halaman post | 1 |
| **Total** | **10** |

---

## 7. Catatan Hasil Pengujian

Berdasarkan pengujian yang dilakukan:

- `flutter analyze` tidak menemukan issue.
- `flutter test` berhasil menjalankan seluruh 10 test.
- Model berhasil menangani field yang hilang.
- Model berhasil menangani field bernilai null.
- Enam kondisi error provider berhasil diuji.
- Provider dapat mengambil data kembali melalui `refresh()`.
- Provider post dan komentar menggunakan instance Dio bersama.
- Widget test halaman post berhasil dijalankan.

Hasil tersebut berasal dari pengujian setelah kode diperbaiki.

Laporan hot restart yang terdapat pada output awal merupakan hasil yang dilaporkan oleh GitHub Copilot. Hot restart belum dijalankan ulang pada tahap pengujian ini.

Halaman aplikasi saat ini masih menampilkan data post. Oleh karena itu, tampilan komentar dan pesan error komentar pada UI belum diuji secara langsung.

Simulasi error pada unit test membuktikan penanganan error pada kode, tetapi tidak membuktikan kondisi jaringan atau error dari server asli.

## Kesimpulan

Hasil pengujian menunjukkan bahwa kode setelah perbaikan berhasil melewati `flutter analyze` tanpa issue dan seluruh 10 test berhasil dijalankan menggunakan `flutter test`.

Model `Comment` berhasil menangani field hilang dan null. Provider komentar juga berhasil menangani beberapa kondisi error serta dapat mengambil data kembali melalui proses refresh.

Namun, pengujian UI komentar belum dilakukan karena fitur komentar belum dihubungkan ke halaman aplikasi.