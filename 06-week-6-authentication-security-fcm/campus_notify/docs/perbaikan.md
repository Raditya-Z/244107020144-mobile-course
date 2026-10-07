# Perbaikan Output AI

## 1. Tujuan Perbaikan

Perbaikan dilakukan setelah kode yang dihasilkan oleh Codex
diverifikasi dan diuji pada aplikasi Campus Notification App.

Hasil awal menunjukkan bahwa sebagian besar implementasi Firebase
Cloud Messaging sudah berjalan, tetapi ditemukan masalah pada
navigasi setelah notifikasi diklik dan proses registrasi token
ke backend.

---

## 2. Masalah Deep Link Notifikasi

Pada pengujian awal, notifikasi foreground berhasil diterima dan
ditampilkan.

Namun, ketika notifikasi diklik, aplikasi tidak berpindah ke halaman:

```text
/pengumuman/3
```

Log menunjukkan:

```text
Payload klik notifikasi:
Navigasi dibatalkan: route tidak valid
```

Hal tersebut menunjukkan bahwa callback klik notifikasi sudah
dijalankan, tetapi payload route yang diterima kosong.

---

## 3. Pemeriksaan Data FCM

Untuk mengetahui penyebab masalah, ditambahkan log pada listener
`onMessage`:

```dart
FirebaseMessaging.onMessage.listen((message) {
  debugPrint('Pesan foreground diterima');
  debugPrint('Data FCM: ${message.data}');

  unawaited(_guard(() => _show(message)));
});
```

Hasil pemeriksaan menunjukkan:

```text
Data FCM: {route          : /pengumuman/3, id: 3}
```

Dari hasil tersebut diketahui bahwa key `route` pada Custom Data
Firebase memiliki spasi tambahan.

Sementara itu, kode Flutter membaca data menggunakan:

```dart
message.data['route']
```

Karena nama key harus sama persis, key yang memiliki spasi tidak
dapat ditemukan menggunakan `message.data['route']`.

Akibatnya payload local notification menjadi kosong.

---

## 4. Perbaikan Custom Data Firebase

Custom Data pada Firebase kemudian diperbaiki.

### Sebelum

```text
route          = /pengumuman/3
id             = 3
```

### Sesudah

```text
route = /pengumuman/3
id = 3
```

Setelah perbaikan, data FCM dapat dibaca dengan benar:

```text
Data FCM: {route: /pengumuman/3, id: 3}
```

Payload notifikasi kemudian berisi:

```text
/pengumuman/3
```

---

## 5. Hasil Perbaikan Deep Link

Setelah Custom Data diperbaiki, klik notifikasi berhasil menjalankan
navigasi menuju:

```text
/pengumuman/3
```

Aplikasi kemudian menampilkan:

```text
Detail Pengumuman
Pengumuman ID: 3
```

Pengujian dilakukan kembali pada tiga kondisi aplikasi.

| State | Hasil |
|---|---|
| Foreground | Berhasil |
| Background | Berhasil |
| Terminated | Berhasil |

Dengan demikian, masalah deep link telah berhasil diperbaiki.

---

## 6. Penanganan Klik Notifikasi

Kode hasil AI menggunakan fungsi `_open()` untuk melakukan validasi
route sebelum navigasi.

Pada proses debugging ditambahkan log:

```dart
void _open(Object? value) {
  debugPrint('Payload klik notifikasi: $value');

  if (_disposed || value is! String) {
    debugPrint('Navigasi dibatalkan: payload bukan String');
    return;
  }

  final uri = Uri.tryParse(value);

  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !(uri.path == '/' ||
          uri.path == '/login' ||
          RegExp(r'^/pengumuman/[^/]+$').hasMatch(uri.path))) {
    debugPrint('Navigasi dibatalkan: route tidak valid');
    return;
  }

  debugPrint('Route valid, navigasi ke: $value');

  go(value);
}
```

Log tersebut digunakan untuk memastikan bahwa payload berhasil
diterima sebelum proses navigasi dilakukan.

---

## 7. Masalah Registrasi Token Backend

Selain masalah deep link, ditemukan log:

```text
Operasi push gagal: StateError
```

Setelah kode diperiksa, error berasal dari proses registrasi FCM
token ke backend.

Pada `main.dart`, alamat backend diperoleh dari:

```dart
const String.fromEnvironment('DEVICES_API_BASE_URL')
```

Sedangkan aplikasi dijalankan menggunakan:

```text
flutter run
```

tanpa memberikan nilai `DEVICES_API_BASE_URL`.

Akibatnya `baseUrl` backend kosong.

---

## 8. Pemeriksaan Endpoint

Pada `PushService`, endpoint diperiksa sebelum token dikirim:

```dart
final endpoint = Uri.tryParse(devicesApi.options.baseUrl);

if (endpoint == null ||
    endpoint.scheme != 'https' ||
    endpoint.host.isEmpty) {
  throw StateError(
    'Konfigurasikan DEVICES_API_BASE_URL ke backend kampus HTTPS.',
  );
}
```

Kode tersebut mencegah FCM token dikirim ke endpoint yang tidak valid
atau tidak aman.

Implementasi pengiriman token sudah disediakan melalui:

```text
POST /devices
```

dengan data:

```dart
{
  'token': token,
  'platform': defaultTargetPlatform.name,
}
```

Listener `onTokenRefresh` juga telah memanggil proses pengiriman token
yang baru ke endpoint tersebut.

---

## 9. Keputusan untuk Backend

Pada praktikum ini belum tersedia backend kampus HTTPS untuk endpoint:

```text
POST /devices
```

Oleh karena itu, alamat backend palsu atau endpoint publik lain tidak
digunakan hanya untuk menghilangkan error.

Implementasi `POST /devices` tetap dipertahankan dan didokumentasikan
sebagai endpoint yang harus digunakan ketika backend tersedia.

Error registrasi token juga sudah ditangani sehingga tidak menyebabkan
aplikasi berhenti dan tidak mengganggu penerimaan notifikasi FCM.

---

## 10. Hasil Akhir Perbaikan

| Bagian | Sebelum | Sesudah |
|---|---|---|
| FCM diterima | Berhasil | Berhasil |
| Foreground notification | Berhasil | Berhasil |
| Payload `route` | Tidak terbaca | Berhasil terbaca |
| Klik foreground | Gagal navigasi | Berhasil |
| Klik background | Belum diuji | Berhasil |
| Klik terminated | Belum diuji | Berhasil |
| `/pengumuman/3` | Tidak terbuka | Berhasil |
| `POST /devices` | Backend belum tersedia | Didokumentasikan |
| `onTokenRefresh` | Sudah diimplementasikan | Dipertahankan |

---

## 11. Keputusan Akhir

Kode hasil Codex tidak langsung dianggap benar hanya karena berhasil
dikompilasi.

Verifikasi menunjukkan bahwa implementasi utama PushService sudah
sesuai kebutuhan, tetapi ditemukan masalah pada konfigurasi Custom
Data Firebase.

Perbaikan dilakukan dengan memastikan key `route` ditulis dengan benar
tanpa spasi tambahan.

Setelah perbaikan, notifikasi berhasil bekerja pada tiga kondisi:

```text
Foreground
Background
Terminated
```

dan klik notifikasi berhasil membuka:

```text
/pengumuman/3
```

Implementasi pengiriman token melalui `POST /devices` dan
`onTokenRefresh` tetap dipertahankan, tetapi pengujian aktual ke backend
belum dilakukan karena backend belum tersedia.

Dengan demikian, hasil AI diterima setelah melalui pemeriksaan,
perbaikan konfigurasi, dan pengujian manual.