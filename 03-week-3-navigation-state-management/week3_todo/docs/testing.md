# Hasil Testing

Setelah kode dari GitHub Copilot diverifikasi dan diperbaiki, saya melakukan pengujian menggunakan `flutter analyze` dan `flutter test`.

Tujuan pengujian ini adalah memastikan kode tidak memiliki masalah pada analyzer dan seluruh test dapat dijalankan dengan benar.

## 1. Flutter Analyze

Perintah yang digunakan:

```bash
flutter analyze
```

### Hasil Pengujian Awal

Pada pengujian pertama ditemukan satu issue:

```text
prefer_initializing_formals
```

Issue tersebut terdapat pada constructor `StatsNotifier`.

Kode awal:

```dart
StatsNotifier({double Function()? failureChance})
    : _failureChance = failureChance;

final double Function()? _failureChance;
```

Kemudian kode diperbaiki menjadi:

```dart
StatsNotifier({
  this.failureChance,
});

final double Function()? failureChance;
```

Penggunaan variabel pada method `build()` juga disesuaikan dari:

```dart
final chance = _failureChance?.call() ?? Random().nextDouble();
```

menjadi:

```dart
final chance = failureChance?.call() ?? Random().nextDouble();
```

### Hasil Setelah Perbaikan

Setelah melakukan perbaikan, saya menjalankan kembali:

```bash
flutter analyze
```

Hasilnya:

```text
No issues found!
```

Dengan demikian, kode sudah lolos pemeriksaan `flutter analyze` tanpa issue.

---

## 2. Flutter Test

Setelah proses analyze selesai, saya menjalankan:

```bash
flutter test
```

### Pengujian Pertama

Pada pengujian pertama masih ditemukan beberapa kegagalan.

Salah satu error yang muncul adalah:

```text
Bad state: No ProviderScope found
```

Hal ini terjadi karena `StatsPage` menggunakan Riverpod melalui `ref.watch(statsProvider)`, sedangkan pada `widget_test.dart`, widget belum dibungkus dengan `ProviderScope`.

Selain itu, `widget_test.dart` masih menggunakan test bawaan Flutter:

```text
Counter increments smoke test
```

Test tersebut masih mencari angka `0`, angka `1`, dan tombol dengan icon `+`.

Test tersebut sudah tidak sesuai karena aplikasi sekarang menggunakan `StatsPage`, bukan aplikasi counter bawaan Flutter.

### Perbaikan Widget Test

Widget test kemudian diperbaiki dengan menambahkan `ProviderScope`:

```dart
await tester.pumpWidget(
  const ProviderScope(
    child: MyApp(),
  ),
);
```

Test counter bawaan Flutter juga diganti menjadi test untuk halaman statistik:

```dart
expect(find.text('Statistik'), findsOneWidget);
expect(find.byType(CircularProgressIndicator), findsOneWidget);
```

Dengan test tersebut, aplikasi diperiksa apakah berhasil menampilkan halaman `StatsPage` dan menampilkan loading indicator ketika data masih diproses.

---

## 3. Perbaikan Unit Test StatsNotifier

Pada pengujian kondisi error, test sempat mengalami timeout.

Untuk membuat kondisi test lebih terkontrol, `ProviderContainer` diberikan konfigurasi:

```dart
retry: (retryCount, error) => null,
```

Konfigurasi tersebut digunakan agar provider tidak melakukan retry ketika terjadi error selama unit test.

### Test Kondisi Berhasil

Kondisi berhasil dibuat menggunakan:

```dart
statsProvider.overrideWith(
  () => StatsNotifier(failureChance: () => 0.9),
),
```

Nilai `0.9` digunakan agar kondisi gagal 30% tidak terjadi sehingga notifier menghasilkan data statistik.

Hasil kemudian diperiksa:

```dart
expect(result.length, 3);
expect(result[0].title, 'Total Pengguna');
expect(result[1].title, 'Pesanan Selesai');
expect(result[2].title, 'Pendapatan');
```

### Test Kondisi Gagal

Kondisi gagal dibuat menggunakan:

```dart
statsProvider.overrideWith(
  () => StatsNotifier(failureChance: () => 0.1),
),
```

Nilai `0.1` berada di bawah `0.3`, sehingga notifier menghasilkan `Exception`.

Pemeriksaan error dilakukan menggunakan:

```dart
await expectLater(
  container.read(statsProvider.future),
  throwsA(isA<Exception>()),
);
```

---

## 4. Perbaikan Pending Timer

Setelah perbaikan sebelumnya, unit test `StatsNotifier` berhasil, tetapi widget test masih mengalami error:

```text
A Timer is still pending even after the widget tree was disposed.
```

Hal ini terjadi karena pada `StatsNotifier` terdapat simulasi pengambilan data selama 2 detik:

```dart
await Future<void>.delayed(
  const Duration(seconds: 2),
);
```

Sedangkan widget test sudah selesai sebelum timer tersebut selesai.

Untuk mengatasinya, pada `widget_test.dart` ditambahkan:

```dart
await tester.pump(
  const Duration(seconds: 2),
);
```

Kode tersebut membuat waktu pada widget test berjalan selama 2 detik sehingga timer dari `StatsNotifier` dapat diselesaikan sebelum test berakhir.

---

## 5. Hasil Akhir Flutter Test

Setelah seluruh perbaikan dilakukan, saya menjalankan kembali:

```bash
flutter test
```

Hasil akhir:

```text
00:07 +3: All tests passed!
```

Artinya seluruh test berhasil dijalankan.

Tiga test yang berhasil terdiri dari:

1. Widget test untuk memastikan halaman statistik dan loading indicator dapat ditampilkan.
2. Unit test untuk memastikan `StatsNotifier` menghasilkan tiga data statistik ketika proses berhasil.
3. Unit test untuk memastikan `StatsNotifier` menghasilkan error ketika proses pengambilan data gagal.

---

## Kesimpulan

Berdasarkan proses pengujian yang dilakukan:

- `flutter analyze` berhasil tanpa issue.
- `flutter test` berhasil menjalankan seluruh test.
- `StatsPage` dapat menggunakan Riverpod melalui `ProviderScope`.
- Kondisi loading dapat diuji melalui widget test.
- Kondisi success pada `StatsNotifier` berhasil diuji.
- Kondisi error pada `StatsNotifier` berhasil diuji.
- Retry provider pada unit test dibuat terkontrol.
- Delay 2 detik pada widget test berhasil ditangani.

Hasil akhir pengujian:

```text
flutter analyze
No issues found!

flutter test
00:07 +3: All tests passed!
```

Dengan demikian, kode hasil AI tidak langsung digunakan, tetapi sudah melalui proses verifikasi, perbaikan, dan testing terlebih dahulu.