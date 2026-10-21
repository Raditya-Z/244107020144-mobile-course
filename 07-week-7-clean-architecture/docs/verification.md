# Verification AI Challenge

## 1. Tujuan Verifikasi

Verifikasi dilakukan untuk memastikan kode yang dihasilkan oleh Codex
sesuai dengan kebutuhan AI Challenge pada Campus Notification App.

Verifikasi dilakukan terhadap:

- background handler;
- permission notifikasi;
- FCM token;
- token refresh;
- local notification;
- deep link;
- topic subscription;
- keamanan token;
- pengujian Foreground, Background, dan Terminated.

---

## 2. Checklist Verifikasi

| No | Kriteria | Hasil |
|---|---|---|
| 1 | Background handler dibuat sebagai fungsi top-level | ✅ Sesuai |
| 2 | Menggunakan `@pragma('vm:entry-point')` | ✅ Sesuai |
| 3 | Background handler tidak menggunakan `BuildContext` | ✅ Sesuai |
| 4 | Menggunakan `requestPermission()` | ✅ Sesuai |
| 5 | Menggunakan `getToken()` | ✅ Sesuai |
| 6 | Menggunakan `onTokenRefresh` | ✅ Sesuai |
| 7 | Token baru diarahkan ke `POST /devices` | ✅ Diimplementasikan |
| 8 | Foreground menggunakan local notification manual | ✅ Sesuai |
| 9 | Background menggunakan `onMessageOpenedApp` | ✅ Sesuai |
| 10 | Terminated menggunakan `getInitialMessage()` | ✅ Sesuai |
| 11 | Subscribe topic `pengumuman-kampus` | ✅ Sesuai |
| 12 | Unsubscribe topic tersedia | ✅ Sesuai |
| 13 | Route dibaca dari `data.route` | ✅ Sesuai |
| 14 | Klik Foreground menuju route yang benar | ✅ Berhasil |
| 15 | Klik Background menuju route yang benar | ✅ Berhasil |
| 16 | Klik Terminated menuju route yang benar | ✅ Berhasil |
| 17 | Token/secret tidak di-hardcode | ✅ Sesuai |
| 18 | Token tidak dicetak secara penuh pada log | ✅ Sesuai |

---

## 3. Verifikasi Background Handler

Background handler telah dibuat sebagai fungsi top-level:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint(
    'Pesan background diterima: ${message.messageId}',
  );

  debugPrint('Data: ${message.data}');
}
```

Handler kemudian didaftarkan menggunakan:

```dart
FirebaseMessaging.onBackgroundMessage(
  firebaseMessagingBackgroundHandler,
);
```

Background handler tidak melakukan navigasi dan tidak menggunakan
`BuildContext`.

**Hasil: Sesuai**

---

## 4. Verifikasi Permission

Aplikasi meminta permission menggunakan:

```dart
final settings = await _messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

Implementasi juga memberikan keterangan perbedaan platform:

- Android 13+ memerlukan runtime notification permission.
- Android versi sebelumnya tidak menggunakan dialog runtime yang sama.
- iOS menggunakan permission alert, badge, dan sound.

**Hasil: Sesuai**

---

## 5. Verifikasi FCM Token

FCM token diperoleh menggunakan:

```dart
final token = await _messaging.getToken();
```

Token kemudian diproses melalui:

```dart
_postToken(token);
```

Implementasi tidak mencetak token FCM secara penuh ke terminal.

**Hasil: Sesuai**

---

## 6. Verifikasi Token Refresh

Listener token refresh telah dibuat:

```dart
_messaging.onTokenRefresh.listen(
  (token) {
    unawaited(
      _guard(() => _postToken(token)),
    );
  },
);
```

Token baru tidak hanya ditampilkan melalui log, tetapi diteruskan
ke fungsi `_postToken()`.

Fungsi tersebut mempersiapkan request:

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

Dengan demikian mekanisme pengiriman token baru ke backend sudah
diimplementasikan.

Backend kampus belum tersedia sehingga request aktual belum dapat
diverifikasi sampai berhasil diterima oleh server.

**Hasil: Implementasi sesuai, backend belum tersedia**

---

## 7. Verifikasi Foreground

Ketika aplikasi berada pada kondisi Foreground, pesan diterima melalui:

```dart
FirebaseMessaging.onMessage.listen(...)
```

Notifikasi kemudian ditampilkan secara manual menggunakan:

```dart
FlutterLocalNotificationsPlugin
```

Custom Data yang digunakan:

```text
route = /pengumuman/3
id = 3
```

Setelah notifikasi diklik, aplikasi berhasil membuka:

```text
/pengumuman/3
```

dan menampilkan:

```text
Pengumuman ID: 3
```

**Hasil: Berhasil**

---

## 8. Verifikasi Background

Ketika aplikasi berada di Background, notifikasi sistem berhasil
ditampilkan.

Klik notifikasi ditangani melalui:

```dart
FirebaseMessaging.onMessageOpenedApp.listen(...)
```

Data route berhasil dibaca dan aplikasi membuka:

```text
/pengumuman/3
```

Halaman menampilkan:

```text
Pengumuman ID: 3
```

**Hasil: Berhasil**

---

## 9. Verifikasi Terminated

Aplikasi ditutup dari Recent Apps kemudian notifikasi dikirim.

Notifikasi sistem berhasil muncul.

Ketika notifikasi diklik, aplikasi dibuka kembali dan pesan diperoleh
menggunakan:

```dart
final initial = await _messaging.getInitialMessage();
```

Route dari pesan kemudian digunakan untuk membuka:

```text
/pengumuman/3
```

Halaman menampilkan:

```text
Pengumuman ID: 3
```

**Hasil: Berhasil**

---

## 10. Verifikasi Topic

Topic yang digunakan adalah:

```text
pengumuman-kampus
```

Subscribe:

```dart
Future<void> subscribeTopic() =>
    _messaging.subscribeToTopic(topic);
```

Unsubscribe:

```dart
Future<void> unsubscribeTopic() =>
    _messaging.unsubscribeFromTopic(topic);
```

**Hasil: Sesuai**

---

## 11. Verifikasi Deep Link

Route diperoleh dari:

```dart
message.data['route']
```

Route kemudian divalidasi oleh fungsi `_open()` sebelum diteruskan
ke callback navigasi.

Contoh payload:

```text
route = /pengumuman/3
```

Target berhasil dibuka:

```text
Detail Pengumuman
Pengumuman ID: 3
```

**Hasil: Berhasil**

---

## 12. Temuan Saat Verifikasi

Pada pengujian awal ditemukan masalah ketika notifikasi Foreground
diklik.

Log menunjukkan:

```text
Payload klik notifikasi:
Navigasi dibatalkan: route tidak valid
```

Setelah dilakukan pemeriksaan, data FCM terbaca:

```text
{route          : /pengumuman/3, id: 3}
```

Key `route` ternyata memiliki spasi tambahan sehingga:

```dart
message.data['route']
```

tidak menemukan nilai yang sesuai.

Custom Data kemudian diperbaiki menjadi:

```text
route = /pengumuman/3
id = 3
```

Setelah perbaikan, navigasi berhasil pada Foreground, Background,
dan Terminated.

---

## 13. Verifikasi Pengiriman Token Backend

Pada terminal ditemukan:

```text
Operasi push gagal: StateError
```

Pemeriksaan menunjukkan bahwa error terjadi karena:

```dart
const String.fromEnvironment(
  'DEVICES_API_BASE_URL',
)
```

belum memiliki nilai.

Backend HTTPS untuk:

```text
POST /devices
```

belum tersedia pada praktikum.

Kode hasil AI sengaja memeriksa validitas endpoint agar token tidak
dikirim ke endpoint yang tidak valid atau tidak aman.

Oleh karena itu, implementasi token backend dipertahankan dan
didokumentasikan, tetapi keberhasilan penerimaan token oleh backend
belum diklaim.

---

## 14. Hasil Pengujian Tiga State

| Kondisi | Notifikasi | Deep Link | Hasil |
|---|---|---|---|
| Foreground | Local notification | `/pengumuman/3` | ✅ Berhasil |
| Background | System notification | `/pengumuman/3` | ✅ Berhasil |
| Terminated | System notification | `/pengumuman/3` | ✅ Berhasil |

---

## 15. Keputusan Akhir

Berdasarkan proses verifikasi, kode hasil Codex telah memenuhi sebagian
besar kebutuhan AI Challenge.

Implementasi yang telah berhasil diverifikasi meliputi:

- permission notifikasi;
- FCM token;
- `onTokenRefresh`;
- background handler;
- local notification Foreground;
- `onMessageOpenedApp`;
- `getInitialMessage`;
- subscribe dan unsubscribe topic;
- pembacaan `data.route`;
- deep link Foreground;
- deep link Background;
- deep link Terminated.

Pada pengujian awal ditemukan kesalahan konfigurasi Custom Data Firebase,
yaitu adanya spasi tambahan pada key `route`. Setelah konfigurasi
diperbaiki, ketiga state berhasil bekerja sesuai kebutuhan.

Mekanisme `POST /devices` juga telah diimplementasikan, tetapi pengujian
aktual terhadap backend belum dilakukan karena backend kampus belum
tersedia.

Dengan demikian, hasil AI **diterima setelah melalui verifikasi,
perbaikan konfigurasi, dan pengujian manual**.