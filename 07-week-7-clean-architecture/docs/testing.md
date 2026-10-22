# Dokumentasi Pengujian

## 1. Tujuan

Pengujian dilakukan untuk memastikan fungsi aplikasi berjalan sesuai harapan. Pengujian domain atau use case sebaiknya tidak bergantung pada jaringan maupun database sungguhan. Fake repository dapat digunakan untuk memberikan hasil yang sudah ditentukan, sehingga skenario sukses dan failure bisa diuji secara terpisah.

## 2. Skenario dan Hasil Pengujian

| Skenario | Tujuan | Hasil yang Diharapkan | Status |
|---|---|---|---|
| Use case sukses dengan fake repository | Memastikan hasil sukses diteruskan sesuai kontrak domain. | Data diterima tanpa failure. | Perlu diverifikasi karena test khusus use case dengan fake repository belum ditemukan. |
| Use case failure dengan fake repository | Memastikan kegagalan ditangani sesuai kontrak domain. | Failure diterima sesuai perilaku yang dirancang. | Perlu diverifikasi karena test khusus failure dengan fake repository belum ditemukan. |
| Routing pesan push | Memeriksa route kosong, route tanpa slash, dan payload dengan ID pengumuman. | Route sesuai ekspektasi test. | Lulus berdasarkan hasil `flutter test` terbaru. |
| Status autentikasi dan pesan error API | Memeriksa status login berdasarkan token, kegagalan refresh auth, error 401, dan timeout. | Status dan pesan error sesuai ekspektasi test. | Lulus berdasarkan hasil `flutter test` terbaru. |
| Seluruh automated test | Memastikan seluruh test yang tersedia berjalan dengan baik. | Semua test yang ada lulus. | Lulus: 6 test berhasil. |
| Pengujian manual setelah refactor | Memastikan perilaku dan tampilan aplikasi tetap berjalan seperti sebelumnya. | Fitur yang tersedia berfungsi setelah refactor. | Perlu diverifikasi karena belum ada bukti pengujian manual. |

## 3. Perintah Pengujian

Pengujian dijalankan dari direktori proyek `07-week-7-clean-architecture` menggunakan perintah:

```powershell
flutter test --reporter expanded
```

Hasil eksekusi terbaru:

```text
00:00 +0: loading test/auth_push_test.dart
00:00 +1: routeFromMessage menangani route kosong dan tanpa slash
00:00 +2: routeFromMessage data payload membawa id pengumuman
00:00 +3: Auth provider auth membaca status login dari token
00:00 +4: Auth refresh gagal menyebabkan sesi dibersihkan
00:00 +5: apiErrorMessage status 401 menghasilkan pesan sesi berakhir
00:00 +6: apiErrorMessage timeout menghasilkan pesan koneksi timeout
00:00 +6: All tests passed!
```

Berdasarkan hasil tersebut, enam test yang tersedia berhasil dijalankan. Namun, test tersebut belum membuktikan bahwa use case domain telah diuji menggunakan fake repository.

## 4. Kesimpulan

Hasil pengujian otomatis menunjukkan bahwa enam test yang tersedia lulus. Pengujian tersebut mencakup routing pesan push, status autentikasi, dan pemetaan pesan error API. Pengujian sukses dan failure pada domain menggunakan fake repository masih perlu dilengkapi atau diverifikasi. Pengujian manual setelah refactor juga perlu dilakukan untuk memastikan perilaku aplikasi tetap sama.