import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../providers/notes_providers.dart';
import '../widgets/add_note_sheet.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final query = ref.watch(searchQueryProvider);
    final hasQuery = query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: hasQuery ? null : const Text('Catatan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).update(value),
              decoration: const InputDecoration(
                labelText: 'Cari judul catatan',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: state.when(
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
                hasQuery
                    ? 'Tidak ada catatan yang cocok.'
                    : 'Belum ada catatan.',
              ),
            );
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final note = filtered[index];

              return ListTile(
                title: Text(note.title),
                subtitle: note.body.isEmpty ? null : Text(note.body),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddNoteSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
    );
  }
}
