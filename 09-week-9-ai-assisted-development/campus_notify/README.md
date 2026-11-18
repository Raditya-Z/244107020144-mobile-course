## Praktikum 1 — Audit Layer Project Lama

### A. Pemetaan File ke Layer

| File | Layer Saat Ini | Hasil Audit |
|---|---|---|
| lib/pages/announcement_page.dart | Presentation | Perlu diperiksa apakah mengakses data langsung |
| lib/pages/home_page.dart | Presentation | Perlu diperiksa apakah terdapat logika bisnis |
| lib/pages/login_page.dart | Presentation | Perlu diperiksa pemisahan UI dan autentikasi |
| lib/providers/auth_provider.dart | Presentation | Provider membuat AuthRepository dan TokenStore secara langsung |
| lib/data/api_client.dart | Data | Perlu diperiksa penggunaan dan tanggung jawabnya |
| lib/data/api_errors.dart | Data | Perlu diperiksa pemisahan penanganan error |
| lib/data/auth_repository.dart | Data | Kontrak dan implementasi repository belum dipisahkan |
| lib/data/token_store.dart | Data | Perlu diperiksa tanggung jawab penyimpanan token |
| lib/messaging/push_service.dart | Infrastruktur | Perlu diperiksa pemisahan layanan push notification |
| lib/main.dart | Bootstrap | Titik masuk aplikasi |
| lib/router.dart | Navigasi | Perlu diperiksa konfigurasi routing |
| lib/routes.dart | Navigasi | Perlu diperiksa pengelolaan konstanta rute |

### B. Hasil Pemeriksaan Pola Kode

1. Pemeriksaan akses jaringan dan database pada
   lib/pages dan lib/providers:
   Tidak ditemukan pola yang dicari.

2. Pemeriksaan DateFormat, jsonDecode, dan
   toIso8601String pada lib/pages dan lib/widgets:
   Tidak ditemukan pola yang dicari.

3. Pemeriksaan instansiasi Repository dan Dio:
   Ditemukan AuthRepository() pada
   lib/providers/auth_provider.dart baris 11.

Catatan: hasil pencarian pola tidak membuktikan
bahwa seluruh project bebas pelanggaran arsitektur.
Pemeriksaan kode tetap diperlukan.

### C. Temuan Utama

AuthRepository saat ini merupakan kelas konkret yang
menangani login dan refresh token menggunakan simulasi.
Interface repository belum dipisahkan ke domain.

AuthNotifier sudah menggunakan Riverpod untuk mengelola
state autentikasi. Provider menjadi tempat pembuatan
dependensi, tetapi cara pemisahan kontrak dan implementasi
repository perlu diperbaiki pada tahap refactoring.

### D. Struktur Target

Refactoring akan menggunakan pendekatan feature-first
dengan tiga layer utama:

- Domain: entity, kontrak repository, use case, dan failure.
- Data: model dan implementasi repository.
- Presentation: halaman, provider, dan pengelolaan state.

Arah dependensi:
Presentation -> Domain <- Data


## Praktikum 2 — Pemisahan Domain dan Data per Fitur

### A. Perubahan Struktur

Refactoring dilakukan secara bertahap pada fitur autentikasi
dengan pendekatan feature-first.

Struktur fitur Auth saat ini:

- `lib/features/auth/domain/entities/auth_session.dart`
  - Menyimpan entity AuthSession yang berisi access token
    dan refresh token.
- `lib/features/auth/domain/repositories/auth_repository.dart`
  - Mendefinisikan kontrak AuthRepository untuk operasi
    login dan refresh token.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - Mengimplementasikan kontrak AuthRepository menggunakan
    simulasi login dan refresh token.
- `lib/features/auth/data/services/token_store.dart`
  - Menangani penyimpanan, pembacaan, dan penghapusan token
    menggunakan FlutterSecureStorage.

### B. Penyesuaian Dependensi

1. `lib/providers/auth_provider.dart` menggunakan kontrak
   AuthRepository dari Domain dan membuat implementasi
   AuthRepositoryImpl melalui provider Riverpod.
2. `lib/data/api_client.dart` menggunakan kontrak
   AuthRepository dari Domain untuk proses refresh token.
3. TokenStore dipindahkan dari `lib/data/` ke
   `lib/features/auth/data/services/`.
4. Implementasi AuthRepository lama di
   `lib/data/auth_repository.dart` dihapus setelah
   implementasi baru digunakan.

### C. Verifikasi

- `flutter analyze`: lulus, tidak ditemukan masalah statis.
- `flutter test`: lulus, seluruh 6 pengujian berhasil.

### D. Catatan

Implementasi login dan refresh token masih menggunakan
simulasi (mock), belum terhubung ke backend autentikasi
yang sesungguhnya.

Pemisahan Domain dan Data telah diterapkan pada bagian
autentikasi yang dikerjakan. Refactoring fitur lain dan
pemisahan use case belum dinyatakan selesai.

---

# Praktikum 3: Presentation, DI, dan Verifikasi

## 1. Dependency Injection dengan Riverpod

Dependency injection diterapkan menggunakan Riverpod tanpa package DI tambahan.

Pada fitur Notes, `notes_providers.dart` menghubungkan repository, use case `GetNotes`, dan state yang digunakan oleh halaman Notes. Pada fitur Auth, `auth_provider.dart` menggunakan `LoginUseCase` untuk menjalankan proses login.

Dengan cara ini, halaman tidak perlu membuat repository secara langsung dan lebih mudah diuji.

## 2. Verifikasi Dependency Rule

Pemeriksaan dilakukan menggunakan PowerShell untuk mencari akses data mentah pada presentation dan import framework pada domain.

Hasil pemeriksaan:

- Presentation: tidak ditemukan kecocokan terhadap pola akses Dio, database, secure storage, SharedPreferences, dan JSON yang diperiksa.
- Domain: tidak ditemukan kecocokan terhadap pola import Flutter, Dio, SQLite, dan Firebase yang diperiksa.
- `flutter analyze`: tidak ditemukan masalah.

Pemeriksaan pola memiliki keterbatasan dan tidak menjamin seluruh kemungkinan pelanggaran telah ditemukan.

## 3. Hasil Pengujian

```text
flutter analyze
No issues found!

flutter test
All tests passed!
```

Hasil terakhir menunjukkan 12 test lulus.

---

# AI Challenge

AI Challenge dilakukan dengan menggunakan Claude untuk memberikan usulan struktur feature-first Clean Architecture. Output AI digunakan sebagai bahan evaluasi, bukan langsung diterapkan seluruhnya.

## Evaluasi dan Keputusan

| Aspek | Keputusan |
|---|---|
| Repository interface | Diletakkan di domain |
| Repository implementation | Diletakkan di data |
| Dependency injection | Menggunakan Riverpod |
| Use case | Digunakan sesuai kebutuhan fitur |
| Testing | Menggunakan fake repository |
| Fungsi murni | Parsing rute dan formatting tanggal dipisahkan |

Dokumentasi AI Challenge disimpan di folder `docs/`, meliputi prompt, output AI, evaluasi perbaikan, pengujian, dan verifikasi.

---

# Refactoring, Testing, dan Error Umum

## 1. Refactoring

Refactoring yang dilakukan meliputi:

- Menambahkan `LoginUseCase` dan menghubungkannya melalui Riverpod.
- Memindahkan `routeFromMessage()` ke `lib/core/format.dart`.
- Menambahkan `formatDate()` untuk formatting tanggal.
- Mengubah pesan error Notes menjadi lebih ramah pengguna.

## 2. Testing dengan Fake Repository

File `test/get_notes_test.dart` menguji dua skenario:

1. Use case meneruskan daftar catatan dari repository.
2. Use case meneruskan failure tanpa melempar exception.

File `test/format_test.dart` menguji formatting tanggal dan parsing rute tanpa widget.

Hasil pengujian terakhir menunjukkan seluruh 12 test lulus dan `flutter analyze` bersih.

## 3. Error Umum

| Masalah | Solusi |
|---|---|
| Model tidak sesuai dengan entity | Konversi model menjadi entity di batas data |
| Widget mengakses database langsung | Gunakan repository melalui provider |
| Test membutuhkan database | Gunakan fake repository |
| Error teknis tampil kepada pengguna | Kembalikan `Failure` dengan pesan yang sesuai |
| Refactoring mengubah perilaku aplikasi | Jalankan test dan pengujian manual |

---

# Tugas, Refleksi, dan Referensi

## 1. Hasil Mini Project

Mini project melanjutkan repository Week 6 dengan pendekatan feature-first Clean Architecture. Refactoring dilakukan pada fitur Auth dan Notes, fungsi murni, dependency injection, serta pengujian otomatis.

Hasil terakhir menunjukkan `flutter analyze` bersih dan 12 test lulus. Bukti screenshot before/after dan pengujian manual perlu disertakan sesuai kondisi yang benar-benar telah dilakukan.

## 2. Refleksi

**Mengapa repository interface berada di domain?**

Karena domain mendefinisikan kebutuhan operasi tanpa bergantung pada implementasi database atau API. Jika interface hanya berada di data, domain berisiko bergantung pada detail implementasi.

**Kapan use case dibutuhkan?**

Use case berguna ketika operasi memiliki aturan bisnis, orkestrasi beberapa proses, atau logika yang digunakan kembali. Untuk CRUD sederhana, repository dapat langsung digunakan oleh notifier jika tidak menambah nilai dengan lapisan tambahan.

**Apa risiko over-engineering?**

Use case untuk setiap operasi satu baris dapat menambah file dan boilerplate. Abstraksi sebaiknya digunakan ketika memberikan manfaat nyata bagi pemeliharaan dan pengujian.

**Bagian mana dari usulan AI yang disederhanakan?**

Penggunaan use case dipilih sesuai kebutuhan fitur. Refactoring dilakukan secara bertahap dan tidak memindahkan seluruh layanan infrastruktur sekaligus.

