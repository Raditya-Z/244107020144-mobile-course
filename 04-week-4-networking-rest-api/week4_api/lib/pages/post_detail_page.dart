import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.post,
  });

  final int postId;
  final Post? post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jika data post sudah dikirim dari halaman list,
    // langsung tampilkan tanpa request API lagi.
    if (post != null) {
      return _PostDetailContent(post: post!);
    }

    // Jika halaman dibuka langsung melalui /post/:id,
    // ambil data post melalui repository.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Post'),
      ),
      body: FutureBuilder<Post>(
        future: ref.read(postRepositoryProvider).fetchPost(postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal mengambil detail post.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Post tidak ditemukan.'),
            );
          }

          return _PostDetailContent(
            post: snapshot.data!,
          );
        },
      ),
    );
  }
}

class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(post.body),
          ],
        ),
      ),
    );
  }
}