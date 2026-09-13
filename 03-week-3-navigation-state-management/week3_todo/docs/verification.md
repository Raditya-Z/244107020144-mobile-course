# Verifikasi Output AI

Saya melakukan pengecekan terhadap kode awal yang diberikan GitHub Copilot berdasarkan AI Verification Checklist pada modul.

## 1. Apakah state diubah secara immutable?

**Hasil: Sesuai**

Pada kode tidak terdapat penggunaan:

```dart
state.add()
```

atau perubahan isi List secara langsung.

Class `StatItem` juga menggunakan atribut `final`:

```dart
final String title;
final int value;
```

Data statistik dikembalikan sebagai List baru:

```dart
return const [
  StatItem(title: 'Total Pengguna', value: 1200),
  StatItem(title: 'Pesanan Selesai', value: 845),
  StatItem(title: 'Pendapatan', value: 32500000),
];
```

Jadi data tidak dimodifikasi secara langsung.

---

## 2. Apakah `ref.watch` hanya digunakan di dalam `build`?

**Hasil: Sesuai**

Pada `StatsPage`, `ref.watch` digunakan di dalam method `build`:

```dart
final statsState = ref.watch(statsProvider);
```

Pada callback tombol `Coba Lagi` tidak terdapat penggunaan `ref.watch`.

Kode retry menggunakan:

```dart
onPressed: () => ref.invalidate(statsProvider),
```

`ref.invalidate()` digunakan untuk membuat provider mengambil data kembali.

Jadi `ref.watch` sudah digunakan pada tempat yang sesuai.

---

## 3. Apakah loading, error, dan success ditangani?

**Hasil: Sesuai**

Kode menggunakan:

```dart
statsState.when()
```

untuk menangani tiga kondisi.

### Loading

```dart
loading: () => const Center(
  child: CircularProgressIndicator(),
),
```

Saat data masih diambil, halaman menampilkan loading spinner.

### Error

Pada bagian `error`, halaman menampilkan pesan error dan tombol `Coba Lagi`.

```dart
error: (error, stackTrace) => Center(
```

### Success

Pada bagian `data`, hasil statistik ditampilkan menggunakan:

```dart
ListView.builder
```

Jadi ketiga kondisi `AsyncValue` sudah ditangani.

---

## 4. Apakah provider menggunakan tipe eksplisit?

**Hasil: Perlu diperbaiki**

Output awal Copilot menuliskan provider seperti berikut:

```dart
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
```

Tipe generic pada `AsyncNotifierProvider` memang sudah dituliskan, tetapi tipe variabel `statsProvider` masih menggunakan type inference melalui `final`.

Agar lebih sesuai dengan checklist yang meminta provider dideklarasikan dengan tipe eksplisit, saya akan mengubahnya menjadi:

```dart
final AsyncNotifierProvider<StatsNotifier, List<StatItem>> statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(
  StatsNotifier.new,
);
```

Saya juga tidak menemukan provider lain dengan nama `statsProvider`.

---

## 5. Apakah menggunakan API Riverpod versi lama?

**Hasil: Sesuai**

Kode menggunakan:

```dart
class StatsNotifier extends AsyncNotifier<List<StatItem>>
```

dan:

```dart
AsyncNotifierProvider<StatsNotifier, List<StatItem>>
```

Halaman juga menggunakan:

```dart
class StatsPage extends ConsumerWidget
```

Tidak ditemukan penggunaan:

* `StateNotifier`
* `StateNotifierProvider`
* `StateProvider`
* `Consumer` bertingkat

Jadi bagian ini sudah sesuai dengan pola Riverpod yang diminta pada praktikum.

---

## 6. Pemeriksaan Unit Test

**Hasil: Akan diuji lebih lanjut**

Copilot sudah memberikan dua unit test:

1. Test ketika pengambilan data berhasil.
2. Test ketika pengambilan data gagal.

Pada test berhasil digunakan:

```dart
failureChance: () => 0.9
```

Karena `0.9` lebih besar dari `0.3`, proses akan berhasil.

Pada test gagal digunakan:

```dart
failureChance: () => 0.1
```

Karena `0.1` lebih kecil dari `0.3`, proses akan menghasilkan error.

Namun hasil sebenarnya tetap perlu diperiksa dengan menjalankan:

```bash
flutter test
```

---

## 7. Hasil `flutter analyze`

**Belum diuji**

Pengujian akan dilakukan menggunakan:

```bash
flutter analyze
```

Hasilnya akan dicatat setelah perintah dijalankan.

---

## 8. Hasil `flutter test`

**Belum diuji**

Pengujian akan dilakukan menggunakan:

```bash
flutter test
```

Hasilnya akan dicatat setelah perintah dijalankan.

---

## Kesimpulan

Dari hasil pemeriksaan awal, sebagian besar kode dari GitHub Copilot sudah sesuai dengan requirement.

Hasil verifikasi:

* ✅ State tidak dimutasi secara langsung.
* ✅ `ref.watch` digunakan di dalam `build`.
* ✅ Loading ditangani.
* ✅ Error ditangani.
* ✅ Success ditangani.
* ⚠️ Deklarasi `statsProvider` akan dibuat lebih eksplisit.
* ✅ Menggunakan `AsyncNotifier`.
* ✅ Menggunakan `AsyncNotifierProvider`.
* ✅ Menggunakan `ConsumerWidget`.
* ✅ Tidak menggunakan pola Riverpod lama.
* ⏳ `flutter analyze` belum dijalankan.
* ⏳ `flutter test` belum dijalankan.
