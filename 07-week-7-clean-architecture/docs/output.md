Transisi dari *layer-first flat structure* ke *feature-first Clean Architecture* adalah langkah yang tepat saat aplikasi mulai memiliki interaksi eksternal seperti auth token persistence dan FCM handler. 

Berikut blueprint arsitektur, pemetaan refactor, batas pragmatis (anti over-engineering), serta wiring Riverpod-nya.

---

### 1. Struktur Folder Feature-First Clean Architecture

```text
lib/
├── app.dart
├── main.dart
├── core/
│   ├── constants/
│   │   └── api_endpoints.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── auth_interceptor.dart
│   └── services/
│       └── fcm_service.dart
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── auth_remote_datasource.dart
    │   │   │   └── auth_local_datasource.dart  # SecureStorage/SharedPrefs
    │   │   ├── models/
    │   │   │   └── user_model.dart             # fromJson, toJson
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user.dart                   # Pure Dart entity
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart        # Interface / abstract class
    │   │   └── usecases/                       # Hanya untuk alur orkestrasi
    │   │       └── login_and_sync_fcm_usecase.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── auth_controller.dart        # AsyncNotifier
    │       ├── screens/
    │       │   └── login_screen.dart
    │       └── widgets/
    │           └── login_form.dart
    └── announcements/
        ├── data/
        │   ├── datasources/
        │   │   └── announcement_remote_datasource.dart
        │   ├── models/
        │   │   └── announcement_model.dart
        │   └── repositories/
        │       └── announcement_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── announcement.dart
        │   └── repositories/
        │       └── announcement_repository.dart
        └── presentation/
            ├── controllers/
            │   └── announcement_list_controller.dart
            ├── screens/
            │   └── announcement_list_screen.dart
            └── widgets/
                └── announcement_card.dart
```

---

### 2. Pemetaan File Lama ke Struktur Baru

| File / Komponen Lama | Status | Lokasi Baru & Tindakan |
|---|---|---|
| `lib/messaging/*` (FCM setup) | **Pecah & Pindah** | Pindah ke `core/services/fcm_service.dart`. Tanggung jawabnya murni menangani SDK Firebase Messaging (background handler, token refresh, permission). Sinkronisasi token ke server didelegasikan ke Use Case / Repository. |
| Widget yang memanggil `Dio` langsung | **Hapus & Ganti** | Hapus instansiasi `Dio` di UI. UI hanya membaca state via `ref.watch(controller)` dan memicu aksi via `ref.read(controller.notifier)`. |
| `lib/data/` (Repo campur impl) | **Pecah** | Pisahkan jadi 2 file per fitur: kontrak abstrak di `domain/repositories/{name}_repository.dart` dan implementasi konkret di `data/repositories/{name}_repository_impl.dart`. |
| `lib/data/*_model.dart` | **Pecah** | Pisahkan Entity murni di `domain/entities/` (tanpa serialisasi JSON) dan Model DTO di `data/models/` (ekstensi entity + helper `fromJson`/`toJson`). |
| `lib/providers/*` | **Refactor** | Pindah ke `features/{feature}/presentation/controllers/`. Ubah ChangeNotifier jadul menjadi `AsyncNotifier` (Riverpod 2.x/3.x) yang mengelola status `AsyncValue`. |
| `lib/pages/*` | **Pindah** | Pindah ke `features/{feature}/presentation/screens/`. Bersihkan dari business logic. |

---

### 3. Anti Over-Engineering & Kapan Butuh Use Case

#### A. Bagian yang Berpotensi Over-Engineering
1. **Model vs Entity pada CRUD sederhana**: Jika data pengumuman hanya `id, title, content, date` yang dibaca sekali dan tidak ada mutasi domain yang kompleks, membuat `AnnouncementEntity` terpisah dari `AnnouncementModel` sering kali hanya menghasilkan kode duplikat (copying properties). 
2. **Pass-through Use Case (1-to-1 forwarder)**: Membuat class `GetAnnouncementsUseCase` yang isinya hanya satu baris `return repo.getAnnouncements();` adalah *ceremonial boilerplate*. Ini menambah file tanpa memberi nilai proteksi bisnis atau decoupling yang berarti.

#### B. Kapan Use Case Benar-benar Dibutuhkan vs Langsung ke Repository:
* **Langsung ke Repository via Controller**: Cocok untuk operasi CRUD tunggal (misal: get list, get detail, delete by ID). Controller langsung memanggil `AnnouncementRepository.getAnnouncements()`.
* **Wajib Pakai Use Case**:
  * **Orkestrasi Multi-Repository**: Kasus login di `campus_notify`: alur login butuh `AuthRepository.login()`, dilanjutkan simpan token ke `SecureStorage`, lalu mengambil FCM token dari `FCMService` dan menyetornya ke `AuthRepository.updateFcmToken()`. Ini *domain workflow*, bukan urusan Controller UI.
  * **Business Rule Validation**: Ada aturan validasi sebelum data menyentuh repository (misal: "mahasiswa semester akhir hanya boleh subscribe topik tertentu").
  * **Reusability**: Alur yang sama dieksekusi dari 2 tempat berbeda (misal: dipanggil saat startup app dan dipanggil ulang setelah deep link push notification).

---

### 4. Wiring Dependency Injection dengan Pure Riverpod

Tidak perlu library tambahan seperti `get_it` atau `injectable`. Riverpod bertindak sebagai *compile-time safe dependency tree*.

```dart
// ==========================================
// 1. CORE: Network Providers
// ==========================================
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
  dio.interceptors.add(AuthInterceptor(ref)); // auto attach token
  return dio;
});

// ==========================================
// 2. FEATURE: Data Sources & Repositories
// ==========================================
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

// ==========================================
// 3. USE CASE (Orkestrasi Login + FCM Sync)
// ==========================================
final loginUseCaseProvider = Provider<LoginAndSyncFcmUseCase>((ref) {
  return LoginAndSyncFcmUseCase(
    authRepository: ref.watch(authRepositoryProvider),
    fcmService: ref.watch(fcmServiceProvider),
  );
});

// ==========================================
// 4. PRESENTATION: Controller (AsyncNotifier)
// ==========================================
final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() {
    // Cek sesi lokal awal jika ada
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(loginUseCaseProvider);
      return await useCase.execute(email: email, password: password);
    });
  }
}
```

---

### 5. Trade-off Setiap Keputusan

| Keputusan | Keuntungan (+)| Konsekuensi / Biaya (-) |
|---|---|---|
| **Feature-first** (dibanding Layer-first) | Skalabilitas tinggi. Saat tim menghapus atau merombak fitur `announcements`, seluruh file terkait berada dalam satu folder tanpa tercecer di root `data/` atau `providers/`. | Sedikit lebih banyak navigasi folder di awal, dan butuh disiplin agar modul antar-fitur tidak saling impor secara liar (wajib lewat `core` atau `domain` interface). |
| **Pure Riverpod DI** (dibanding `get_it`) | 100% deklaratif, siklus hidup dependensi (*auto-dispose*, *scoping*) terikat otomatis dengan lifecycle UI Flutter, serta sangat mudah di-*mock* pada unit test via `ProviderContainer(overrides: [...])`. | Semua class yang butuh dependensi harus dihubungkan lewat `Ref`, sehingga class non-UI sedikit terikat dengan konsep provider Riverpod jika tidak diabstraksi dengan baik di entry point. |
| **Pragmatic Use Case** (Use case hanya saat ada orkestrasi) | Memangkas jumlah boilerplate code hingga ~40% pada fitur pembacaan daftar pengumuman sederhana. Waktu iterasi jauh lebih cepat. | Batas arsitektur jadi fleksibel (bukan dogmatis). Membutuhkan pemahaman tim yang seragam mengenai *kapan* suatu logika sudah dianggap cukup rumit untuk diekstrak menjadi Use Case. |
| **Abstraksi Repository Interface** | Widget & Controller terisolasi total dari detail teknis (Dio, SQLite, memory cache), memudahkan unit testing dengan mock interface murni. | Menulis 2 file (`auth_repository.dart` & `auth_repository_impl.dart`) untuk setiap entitas data yang ada. |