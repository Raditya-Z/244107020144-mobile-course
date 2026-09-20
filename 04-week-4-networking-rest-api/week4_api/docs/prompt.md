# Prompt AI Challenge Week 4

Pada AI Challenge Week 4 saya menggunakan **GitHub Copilot** sebagai co-developer untuk membantu membuat repository layer untuk mengambil data komentar dari JSONPlaceholder menggunakan Dio dan Flutter Riverpod.

Prompt yang saya gunakan:

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error
  ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

Prompt tersebut digunakan untuk mendapatkan kode awal dari GitHub Copilot. Hasil kode Copilot terdapat pada `comment.dart`, `comment_repository.dart`, dan `comment_provider.dart`. Salinan kode dan penjelasan sederhananya saya simpan di [output_ai.md](output_ai.md), lalu saya periksa berdasarkan checklist tugas.
