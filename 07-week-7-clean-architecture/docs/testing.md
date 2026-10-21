# Pengujian AI Challenge

## 1. Tujuan Pengujian

Pengujian dilakukan untuk memastikan implementasi Firebase Cloud Messaging
hasil bantuan AI dapat bekerja pada tiga kondisi aplikasi, yaitu
Foreground, Background, dan Terminated.

Payload yang digunakan pada pengujian:

```text
route = /pengumuman/3
id = 3
```

Target navigasi:

```text
/pengumuman/3
```

Halaman yang diharapkan:

```text
Detail Pengumuman
Pengumuman ID: 3
```

---

## 2. Pengujian Foreground

### Kondisi

Aplikasi sedang terbuka dan aktif pada layar.

### Hasil

Notifikasi berhasil diterima melalui `FirebaseMessaging.onMessage`.
Karena aplikasi berada pada kondisi foreground, notifikasi ditampilkan
secara manual menggunakan `flutter_local_notifications`.

Setelah notifikasi diklik, payload `route` berhasil dibaca dan aplikasi
berpindah ke:

```text
/pengumuman/3
```

Halaman menampilkan:

```text
Pengumuman ID: 3
```

**Status: Berhasil**

Bukti screenshot:

```text
HasilAIChallenge-ForegroundNotifikasi.jpg
HasilAIChallenge-ForegroundKlik.jpg
```

---

## 3. Pengujian Background

### Kondisi

Aplikasi masih berjalan tetapi berada di background setelah tombol Home
ditekan.

### Hasil

Notifikasi sistem berhasil muncul.

Ketika notifikasi diklik, aplikasi kembali dibuka dan
`FirebaseMessaging.onMessageOpenedApp` menangani pesan.

Nilai `data.route` berhasil digunakan untuk membuka:

```text
/pengumuman/3
```

Halaman menampilkan:

```text
Pengumuman ID: 3
```

**Status: Berhasil**

Bukti screenshot:

```text
HasilAIChallenge-BackgroundNotifikasi.jpg
HasilAIChallenge-BackgroundKlik.jpg
```

---

## 4. Pengujian Terminated

### Kondisi

Aplikasi ditutup dari Recent Apps sebelum notifikasi dikirim.

### Hasil

Notifikasi sistem berhasil muncul ketika aplikasi dalam kondisi
terminated.

Setelah notifikasi diklik, aplikasi terbuka kembali dan pesan awal
ditangani menggunakan:

```dart
FirebaseMessaging.instance.getInitialMessage()
```

Nilai `data.route` berhasil mengarahkan aplikasi ke:

```text
/pengumuman/3
```

Halaman menampilkan:

```text
Pengumuman ID: 3
```

**Status: Berhasil**

Bukti screenshot:

```text
HasilAIChallenge-TerminatedNotifikasi.jpg
HasilAIChallenge-TerminatedKlik.jpg
```

---

## 5. Hasil Pengujian Tiga State

| State | Notifikasi | Navigasi | Hasil |
|---|---|---|---|
| Foreground | Local notification tampil | `/pengumuman/3` | Berhasil |
| Background | System notification tampil | `/pengumuman/3` | Berhasil |
| Terminated | System notification tampil | `/pengumuman/3` | Berhasil |

---

## 6. Temuan Selama Pengujian

Pada pengujian awal, notifikasi foreground berhasil tampil tetapi ketika
diklik aplikasi tidak berpindah ke halaman pengumuman.

Log menunjukkan:

```text
Payload klik notifikasi:
Navigasi dibatalkan: route tidak valid
```

Setelah dilakukan pemeriksaan terhadap data FCM, ditemukan bahwa key
`route` pada Custom Data Firebase memiliki spasi tambahan.

Data yang salah terbaca seperti:

```text
{route          : /pengumuman/3, id: 3}
```

Sedangkan aplikasi membaca:

```dart
message.data['route']
```

Key Custom Data kemudian diperbaiki menjadi:

```text
route = /pengumuman/3
id = 3
```

Setelah perbaikan, payload berhasil dibaca dan navigasi menuju halaman
pengumuman berhasil dilakukan.

---

## 7. Pengujian Token Backend

Implementasi hasil AI telah menyediakan proses:

```text
getToken()
      ↓
POST /devices
```

serta listener:

```text
onTokenRefresh
      ↓
POST /devices
```

Namun backend kampus untuk endpoint `/devices` belum tersedia pada
praktikum ini.

Karena `DEVICES_API_BASE_URL` belum dikonfigurasi, aplikasi menampilkan:

```text
Operasi push gagal: StateError
```

Kondisi tersebut tidak mengganggu proses penerimaan FCM maupun navigasi
notifikasi.

Endpoint yang dipersiapkan:

```text
POST /devices
```

Data yang akan dikirim:

```text
token
platform
```

---

## 8. Kesimpulan

Berdasarkan pengujian, implementasi Firebase Cloud Messaging berhasil
berjalan pada kondisi Foreground, Background, dan Terminated.

Notifikasi berhasil diterima dan klik notifikasi berhasil membuka route
`/pengumuman/3` sesuai data yang dikirim melalui Firebase.

Ditemukan kesalahan pada penulisan key `route` pada Custom Data Firebase
saat pengujian awal. Setelah key diperbaiki, fitur deep link berhasil
berjalan sesuai kebutuhan.

Pengiriman token ke endpoint `/devices` telah diimplementasikan pada
kode, tetapi pengujian aktual ke backend belum dilakukan karena backend
belum tersedia.