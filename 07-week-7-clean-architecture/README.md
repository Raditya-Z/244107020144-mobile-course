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
