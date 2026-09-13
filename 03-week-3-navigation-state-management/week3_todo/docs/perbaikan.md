# Perbaikan Kode AI

Setelah mendapatkan output awal dari GitHub Copilot, saya melakukan verifikasi berdasarkan checklist praktikum. Dari proses verifikasi dan testing, ditemukan beberapa bagian yang perlu diperbaiki.

## 1. Memperjelas Tipe Provider

Pada output awal AI, provider ditulis:

```dart
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
```

Kemudian saya mengubahnya menjadi:

```dart
final AsyncNotifierProvider<StatsNotifier, List<StatItem>> statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(
  StatsNotifier.new,
);
```

Perubahan dilakukan agar tipe provider dituliskan secara eksplisit sesuai dengan checklist praktikum.

---

## 2. Memperbaiki Constructor StatsNotifier

Saat menjalankan:

```bash
flutter analyze
```

ditemukan issue:

```text
prefer_initializing_formals
```

Constructor awal:

```dart
StatsNotifier({double Function()? failureChance})
    : _failureChance = failureChance;

final double Function()? _failureChance;
```

Kemudian diperbaiki menjadi:

```dart
StatsNotifier({
  this.failureChance,
});

final double Function()? failureChance;
```

Penggunaan variabel pada method `build()` juga diubah dari:

```dart
final chance = _failureChance?.call() ?? Random().nextDouble();
```

menjadi:

```dart
final chance = failureChance?.call() ?? Random().nextDouble();
```

Setelah perbaikan, `flutter analyze` dijalankan kembali dan menghasilkan:

```text
No issues found!
```

---

## 3. Memperbaiki Unit Test Kondisi Error

Pada output awal AI, pemeriksaan error ditulis:

```dart
expect(
  () => container.read(statsProvider.future),
  throwsA(isA<Exception>()),
);
```

Kemudian diperbaiki menjadi:

```dart
await expectLater(
  container.read(statsProvider.future),
  throwsA(isA<Exception>()),
);
```

Perubahan dilakukan karena `statsProvider.future` merupakan proses asynchronous. Dengan `await expectLater`, test menunggu hasil dari `Future` dan memeriksa apakah proses tersebut menghasilkan `Exception`.

---

## 4. Menonaktifkan Retry pada Unit Test

Saat menjalankan `flutter test`, test kondisi error mengalami timeout.

Untuk membuat pengujian lebih terkontrol, saya menambahkan konfigurasi berikut pada `ProviderContainer`:

```dart
retry: (retryCount, error) => null,
```

Contohnya:

```dart
final container = ProviderContainer(
  retry: (retryCount, error) => null,
  overrides: [
    statsProvider.overrideWith(
      () => StatsNotifier(failureChance: () => 0.1),
    ),
  ],
);
```

Konfigurasi tersebut digunakan agar provider tidak terus melakukan retry ketika kondisi error sengaja dibuat pada unit test.

---

## 5. Memperbaiki Widget Test Bawaan Flutter

File `widget_test.dart` awalnya masih menggunakan test counter bawaan Flutter:

```dart
expect(find.text('0'), findsOneWidget);
expect(find.text('1'), findsNothing);

await tester.tap(find.byIcon(Icons.add));
```

Test tersebut sudah tidak sesuai karena aplikasi sekarang menggunakan `StatsPage`, bukan aplikasi counter.

Widget test kemudian diganti menjadi pengujian halaman statistik:

```dart
expect(find.text('Statistik'), findsOneWidget);
expect(
  find.byType(CircularProgressIndicator),
  findsOneWidget,
);
```

Dengan demikian, widget test memeriksa apakah halaman statistik tampil dan loading indicator muncul ketika data masih diproses.

---

## 6. Menambahkan ProviderScope pada Widget Test

Pada pengujian awal muncul error:

```text
Bad state: No ProviderScope found
```

Hal ini terjadi karena `StatsPage` menggunakan Riverpod, tetapi `MyApp` pada widget test belum dibungkus dengan `ProviderScope`.

Kode kemudian diperbaiki menjadi:

```dart
await tester.pumpWidget(
  const ProviderScope(
    child: MyApp(),
  ),
);
```

Dengan `ProviderScope`, provider Riverpod dapat digunakan ketika widget test dijalankan.

---

## 7. Menyelesaikan Pending Timer

Setelah perbaikan sebelumnya, widget test masih menghasilkan error:

```text
A Timer is still pending even after the widget tree was disposed.
```

Hal ini terjadi karena `StatsNotifier` memiliki simulasi delay selama 2 detik:

```dart
await Future<void>.delayed(
  const Duration(seconds: 2),
);
```

Sedangkan widget test selesai sebelum timer tersebut selesai.

Saya menambahkan:

```dart
await tester.pump(
  const Duration(seconds: 2),
);
```

agar waktu pada widget test berjalan selama 2 detik dan timer dapat selesai sebelum pengujian berakhir.

---

## Hasil Setelah Perbaikan

Setelah seluruh perbaikan dilakukan, saya menjalankan:

```bash
flutter analyze
```

Hasil:

```text
No issues found!
```

Kemudian menjalankan:

```bash
flutter test
```

Hasil:

```text
00:07 +3: All tests passed!
```

Dengan demikian, kode hasil AI sudah melalui proses verifikasi, perbaikan, dan testing sebelum digunakan.

## Kesimpulan

Output dari GitHub Copilot tidak langsung saya gunakan tanpa pemeriksaan. Beberapa bagian perlu disesuaikan agar memenuhi checklist praktikum dan dapat melewati proses testing.

Perbaikan yang dilakukan meliputi deklarasi provider, constructor `StatsNotifier`, unit test asynchronous, konfigurasi retry Riverpod, `ProviderScope`, widget test, dan penanganan delay pada widget test.