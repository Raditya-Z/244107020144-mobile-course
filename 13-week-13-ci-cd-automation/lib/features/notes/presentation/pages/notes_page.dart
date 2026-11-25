import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';
import '../widgets/add_note_sheet.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hanya status "ada kueri" yang dipakai untuk judul AppBar, sehingga
    // setiap ketikan tidak membangun ulang Scaffold dan kolom pencarian.
    final hasQuery = ref.watch(
      searchQueryProvider.select((query) => query.trim().isNotEmpty),
    );

    return Scaffold(
      appBar: AppBar(
        title: hasQuery ? null : const Text('Catatan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: const _SearchField(),
          ),
        ),
      ),
      body: const _NotesList(),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-note-fab'),
        onPressed: () => showAddNoteSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
    );
  }
}

/// Widget ini tidak menonton provider kueri, jadi mengetik hanya memperbarui
/// notifier tanpa membangun ulang TextField.
class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      key: const Key('search-notes-field'),
      onChanged: (value) =>
          ref.read(searchQueryProvider.notifier).update(value),
      decoration: const InputDecoration(
        labelText: 'Cari judul catatan',
        prefixIcon: Icon(Icons.search),
        isDense: true,
      ),
    );
  }
}

/// Daftar hasil pencarian dipisah dari Scaffold supaya rebuild akibat kueri
/// dan data catatan terbatas pada area list.
class _NotesList extends ConsumerWidget {
  const _NotesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final query = ref.watch(searchQueryProvider);
    final hasQuery = query.trim().isNotEmpty;

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error is Failure
                  ? error.message
                  : 'Terjadi kesalahan. Silakan coba lagi.',
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(notesProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (notes) {
        final filtered = ref.watch(searchNotesProvider)(
          notes: notes,
          query: query,
        );

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              hasQuery ? 'Tidak ada catatan yang cocok.' : 'Belum ada catatan.',
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) => _NoteTile(note: filtered[index]),
        );
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: note.body.isEmpty ? null : Text(note.body),
    );
  }
}
