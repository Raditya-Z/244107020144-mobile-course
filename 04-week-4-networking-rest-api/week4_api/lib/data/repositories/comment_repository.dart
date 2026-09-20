import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Mengambil data komentar dari JSONPlaceholder.
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil komentar dengan timeout dari client bersama di api_client.dart.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
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
