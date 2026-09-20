import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';
import 'package:week4_api/main.dart';

// Data lokal membuat test tidak bergantung pada internet.
class FakePostRepository extends PostRepository {
  FakePostRepository(super.dio);

  @override
  Future<List<Post>> fetchPostsPage({int page = 1, int limit = 10}) async {
    return [const Post(userId: 1, id: 1, title: 'Post pengujian', body: 'Isi')];
  }
}

void main() {
  testWidgets('Halaman post menampilkan data repository', (tester) async {
    final dio = Dio();
    addTearDown(dio.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(FakePostRepository(dio)),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Posts Paged'), findsOneWidget);
    expect(find.text('Post pengujian'), findsOneWidget);
    expect(find.text('Semua data termuat.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
