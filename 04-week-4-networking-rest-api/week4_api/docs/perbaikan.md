# Perbaikan Kode AI

Setelah mendapatkan kode dari GitHub Copilot, saya memeriksa model, repository, provider, dan test berdasarkan checklist Week 4. Dari pemeriksaan tersebut, terdapat beberapa bagian yang perlu disesuaikan.

Berdasarkan hasil verifikasi, saya melakukan beberapa penyesuaian pada kode agar sesuai dengan struktur project dan requirement Week 4.

Output awal Copilot tetap disimpan di [output_ai.md](output_ai.md), sehingga dapat dibandingkan dengan kode setelah perbaikan.

## 1. Memusatkan Timeout pada Client Dio

Sebelumnya, `comment_repository.dart` mengatur timeout sendiri:

```dart
options: Options(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
),
```

Padahal `api_client.dart` sudah memiliki konfigurasi timeout. Jika timeout diatur pada beberapa tempat, konfigurasi dapat berbeda antara satu repository dengan repository lainnya.

Saya menghapus `Options` pada repository dan melengkapi konfigurasi timeout di `api_client.dart`:

```dart
BaseOptions(
  baseUrl: 'https://jsonplaceholder.typicode.com',
  connectTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {'Accept': 'application/json'},
),
```

Setelah diperbaiki, repository cukup melakukan request seperti berikut:

```dart
final response = await _dio.get<List<dynamic>>(
  '/comments',
  queryParameters: {'postId': postId},
);
```

Dengan perubahan tersebut, pengaturan timeout berada pada satu tempat yaitu `api_client.dart`.

Nilai 10 detik berlaku untuk masing-masing jenis timeout, bukan sebagai batas total seluruh proses request.

## 2. Menggunakan Provider Dio Bersama

Pada kode awal, provider post dan komentar sama-sama membuat Dio melalui `createDio()`. Hal ini menyebabkan terdapat lebih dari satu instance Dio dalam project.

Provider Dio kemudian dipusatkan pada `api_client.dart`:

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio();

  ref.onDispose(() => dio.close());

  return dio;
});
```

Provider komentar kemudian menggunakan provider Dio yang sama:

```dart
final commentDioProvider = dioProvider;
```

Dengan cara tersebut, provider untuk post dan komentar dapat menggunakan client Dio yang sama dalam satu container Riverpod.

`ref.onDispose()` digunakan untuk menutup Dio ketika provider sudah tidak digunakan.

`providers.dart` juga tetap mengekspor `dioProvider`, sehingga kode sebelumnya yang sudah menggunakan provider tersebut tidak perlu banyak diubah.

## 3. Menambahkan Edge Case pada Model

Unit test awal dari Copilot sudah menguji kondisi ketika field JSON tidak tersedia dengan menggunakan:

```dart
final comment = Comment.fromJson({});
```

Namun, pada checklist AI Challenge diminta untuk menambahkan minimal satu edge case sendiri.

Saya menambahkan pengujian ketika seluruh field tersedia tetapi memiliki nilai `null`:

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

Test tersebut memastikan bahwa nilai `null` tetap diubah menjadi nilai default.

Untuk field angka:

```text
null → 0
```

Sedangkan untuk field String:

```text
null → ''
```

Implementasi model tidak perlu diubah karena `Comment.fromJson()` dari Copilot sudah dapat menangani kondisi tersebut.

Namun, cast pada model masih dapat gagal apabila API memberikan tipe data yang berbeda. Contohnya field `name` seharusnya String tetapi API mengirim angka. Kasus tersebut berbeda dengan pengujian field hilang atau bernilai null.

## 4. Menguji Error dan Refresh Provider

Saya menambahkan file:

```text
test/comment_provider_test.dart
```

Test ini digunakan untuk memeriksa penanganan error dan proses refresh pada provider komentar.

Pengujian menggunakan interceptor Dio untuk membuat respons buatan sehingga test tidak bergantung pada koneksi internet.

Beberapa skenario error yang diuji yaitu:

```text
connectionTimeout
sendTimeout
receiveTimeout
connectionError
404
500
```

Pada setiap skenario, test memeriksa beberapa hal yaitu:

- Request menuju endpoint `/comments`.
- `postId` dikirim dengan benar.
- Base URL mengikuti konfigurasi client.
- Timeout mengikuti konfigurasi Dio.
- Error dari Dio berubah menjadi `AsyncError`.
- Error menghasilkan pesan yang sesuai untuk pengguna.
- Request yang gagal hanya dipanggil satu kali sebelum dilakukan refresh.
- Refresh dapat menghasilkan data komentar setelah respons diubah menjadi berhasil.

Untuk memeriksa Future yang menghasilkan error digunakan:

```dart
await expectLater(
  container.read(provider.future),
  throwsA(isA<DioException>()),
);
```

`await expectLater` digunakan agar test menunggu Future selesai dan menghasilkan error sebelum melanjutkan pemeriksaan berikutnya.

Pengaturan retry yang mengembalikan `null` sudah terdapat pada provider:

```dart
retry: (retryCount, error) => null,
```

Dengan demikian, Riverpod tidak melakukan retry otomatis ketika pengujian error dilakukan.

## 5. Memperbaiki Widget Test Bawaan Flutter

Widget test awal masih menggunakan test bawaan Flutter yang mencari angka counter dan tombol tambah.

Test tersebut sudah tidak sesuai dengan aplikasi Week 4 karena halaman utama aplikasi sekarang menampilkan `Posts Paged`.

Oleh karena itu, widget test disesuaikan dengan kondisi aplikasi.

Aplikasi dibungkus menggunakan `ProviderScope` dan repository post diganti dengan repository buatan:

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

Repository buatan digunakan agar widget test mendapatkan data lokal dan tidak melakukan request langsung ke internet.

Widget test kemudian memeriksa beberapa tampilan yaitu:

```text
Posts Paged
Post pengujian
Semua data termuat.
```

Dengan perubahan tersebut, widget test sudah sesuai dengan aplikasi Week 4 yang sedang dibuat.

## 6. Hasil Setelah Perbaikan

Setelah seluruh perbaikan dilakukan, saya menjalankan:

```bash
flutter analyze
```

Hasilnya:

```text
Analyzing week4_api...

No issues found! (ran in 3.8s)
```

Selanjutnya saya menjalankan:

```bash
flutter test
```

Hasilnya:

```text
00:00 +10: All tests passed!
```

Hasil tersebut menunjukkan bahwa setelah perbaikan:

- `flutter analyze` tidak menemukan issue.
- `flutter test` berhasil menjalankan seluruh 10 test.
- Test `Comment.fromJson` untuk field hilang berhasil.
- Edge case field bernilai null berhasil.
- Pengujian error provider berhasil.
- Pengujian refresh provider berhasil.
- Widget test berhasil dijalankan.

## Catatan

Pengujian yang dilakukan pada tahap ini berfokus pada model, repository, provider, error handling, refresh, dan widget test.

Hot restart serta tampilan error komentar pada UI belum diuji ulang karena halaman utama aplikasi masih menampilkan data post.

Pengujian yang sudah dilakukan dan hasil lengkapnya dicatat pada [testing.md](testing.md).

## Kesimpulan

Dari hasil verifikasi, kode awal GitHub Copilot sudah memenuhi sebagian besar requirement AI Challenge, tetapi masih terdapat beberapa bagian yang perlu disesuaikan dengan struktur project Week 4 yang sudah ada.

Perbaikan utama yang dilakukan adalah memusatkan konfigurasi timeout pada client Dio, menggunakan provider Dio bersama, menambahkan edge case untuk nilai null, menambahkan pengujian error dan refresh provider, serta menyesuaikan widget test dengan aplikasi Week 4.

Setelah perbaikan, `flutter analyze` berhasil tanpa issue dan seluruh 10 test berhasil dijalankan menggunakan `flutter test`.