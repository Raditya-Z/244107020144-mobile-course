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
  test('Comment.fromJson memakai nilai default saat semua field null', () {
    final comment = Comment.fromJson({
      'postId': null,
      'id': null,
      'name': null,
      'email': null,
      'body': null,
    });
    expect(comment.toJson(), {
      'postId': 0,
      'id': 0,
      'name': '',
      'email': '',
      'body': '',
    });
  });
}
