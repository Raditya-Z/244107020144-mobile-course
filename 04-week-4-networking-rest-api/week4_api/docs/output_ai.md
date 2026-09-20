# Output Kode Awal GitHub Copilot

Pada AI Challenge Week 4, saya menggunakan GitHub Copilot untuk membuat model, repository, dan provider komentar. Kode hasil Copilot ada pada tiga file berikut. Saya menyalin isinya ke dokumentasi ini agar hasil AI bisa dibaca bersama catatan verifikasinya.

Nama file provider di proyek adalah `comment_provider.dart`.

## 1. Model Comment

File: `lib/data/models/comment.dart`.

Model digunakan untuk menyimpan data satu komentar. `fromJson` mengubah data JSON menjadi objek Comment. Jika field hilang atau null, nilainya diganti dengan 0 atau teks kosong. `toJson` mengubah objek kembali menjadi Map.
```dart
/// Model satu komentar dari endpoint JSONPlaceholder `/comments`.
class Comment {
  /// Membuat komentar dengan nilai yang sudah aman untuk dipakai UI.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Mengubah JSON menjadi model dengan fallback ketika field null atau hilang.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengubah model kembali menjadi bentuk JSON.
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'id': id,
    'name': name,
    'email': email,
    'body': body,
  };
}
```

Penjelasan yang saya pahami:

- `final` berarti nilai field tidak bisa diganti setelah objek dibuat.
- `required` berarti argumen wajib diberikan saat membuat objek.
- `as num?` menerima angka atau null, lalu `toInt()` mengubah angka menjadi integer.
- `?.` menjalankan fungsi hanya jika nilainya tidak null.
- `??` memberi nilai pengganti jika hasil di sebelah kiri null.
- Cast masih bisa gagal jika tipe data berbeda, misalnya nama dikirim sebagai angka.

## 2. CommentRepository

File: `lib/data/repositories/comment_repository.dart`.

Repository bertugas mengambil data dari API. Dengan pemisahan ini, kode request tidak perlu ditulis di halaman aplikasi.
```dart
import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Mengambil data komentar dari JSONPlaceholder.
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil komentar untuk satu post dengan batas waktu 10 detik.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    // Abaikan item yang bukan object JSON agar respons yang tidak valid tidak
    // menyebabkan parsing seluruh daftar gagal.
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
```

Penjelasan yang saya pahami:

- Dio diterima melalui constructor dan disimpan pada `_dio`.
- `Future<List<Comment>>` berarti hasilnya berupa daftar komentar yang tersedia setelah proses async selesai.
- `queryParameters` mengirim postId, sehingga request menjadi `/comments?postId={id}`.
- `Options` mengatur timeout koneksi, penerimaan, dan pengiriman masing-masing 10 detik.
- Jika data respons null, kode memakai daftar kosong.
- `whereType` melewati item yang bukan Map JSON. Ini belum memeriksa tipe setiap field di dalam Map.
- `map(Comment.fromJson)` mengubah setiap Map menjadi objek Comment, lalu `toList()` mengumpulkannya menjadi daftar.

## 3. Provider Komentar dan Pesan Error

File: `lib/data/comment_provider.dart`.

Provider menghubungkan repository dengan state yang nantinya bisa dibaca UI. State digunakan untuk mengetahui apakah data sedang dimuat, berhasil didapat, atau gagal.
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

/// Menyediakan satu instance Dio untuk seluruh repository aplikasi.
final commentDioProvider = Provider<Dio>((ref) => createDio());

/// Menyediakan repository komentar dengan client Dio dari provider di atas.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(commentDioProvider)),
);

/// Memuat komentar berdasarkan postId; exception build otomatis menjadi
/// AsyncError yang dapat ditampilkan oleh UI melalui state.hasError.
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  /// Menyimpan argumen family agar dapat dipakai build dan refresh.
  CommentsNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }

  /// Memuat ulang komentar dan mempertahankan penanganan error Riverpod.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(commentRepositoryProvider).fetchComments(postId),
    );
  }
}

/// Family provider membuat state terpisah untuk setiap postId.
final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
      CommentsNotifier.new,
      // Error tidak di-retry otomatis agar state AsyncError segera tersedia.
      retry: (retryCount, error) => null,
    );

/// Mengubah error Dio menjadi pesan yang dapat dipahami pengguna.
String commentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) return 'Komentar tidak ditemukan (404).';
        if (statusCode == 500) {
          return 'Server sedang bermasalah (500). Coba lagi nanti.';
        }
        return 'Server mengembalikan error ($statusCode). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }

  return 'Terjadi kesalahan tak terduga. Coba lagi.';
}
```

Penjelasan yang saya pahami:

- `commentDioProvider` membuat Dio melalui `createDio()` dari `api_client.dart`.
- `commentRepositoryProvider` menyediakan repository yang memakai Dio tersebut.
- `build()` menjalankan pengambilan komentar. Kegagalan Future dari repository dapat menjadi AsyncError pada Riverpod.
- `refresh()` mengatur state menjadi loading, lalu `AsyncValue.guard` menangkap hasil atau error dari request.
- `family` membuat provider menerima postId dan membedakan state untuk setiap postId.
- `retry` yang mengembalikan null mematikan percobaan ulang otomatis.
- `commentErrorMessage` mengubah error menjadi pesan sederhana untuk pengguna. Fungsi ini harus dipanggil oleh UI agar pesannya tampil.

Catatan verifikasi: komentar kode yang menyebut satu instance Dio untuk seluruh repository belum sesuai dengan kondisi proyek, karena fitur post masih mempunyai `dioProvider` sendiri. Catatan ini tidak mengubah salinan kode Copilot di atas.

## 4. Unit Test Pendukung

File: `test/comment_test.dart`. Test ini juga disebut dalam ringkasan hasil Copilot.
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson memakai nilai aman saat field hilang', () {
    // JSON yang tidak lengkap harus tetap menghasilkan model yang valid.
    final comment = Comment.fromJson({});

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}
```

Test memasukkan JSON kosong dan memeriksa kelima nilai default dengan `expect`. Jadi, kasus yang diuji adalah field hilang, bukan hanya data lengkap.

## Ringkasan Validasi dari Copilot

Copilot melaporkan unit test lulus, `flutter analyze` tanpa issue, dan hot restart sukses. Copilot juga menjelaskan bahwa timeout, AsyncError, refresh, retry yang dimatikan, dan pesan error sudah ditambahkan.

Hasil pemeriksaan kode dicatat di [verification.md](verification.md). Catatan perbaikan ada di [perbaikan.md](perbaikan.md), sedangkan hasil dan batas pengujian ada di [testing.md](testing.md).

