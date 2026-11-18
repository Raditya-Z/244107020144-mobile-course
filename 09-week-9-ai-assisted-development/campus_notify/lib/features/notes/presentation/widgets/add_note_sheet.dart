import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_providers.dart';

/// Menambah catatan lewat abstraksi NoteRepository (domain), bukan SQLite
/// langsung dari widget. Judul kosong tidak bisa disimpan (validasi minimal
/// mengikuti pola aplikasi Offline Notes Minggu 5/8).
Future<void> showAddNoteSheet(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final messenger = ScaffoldMessenger.of(context);

  final title = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Judul catatan'),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final valid = controller.text.trim().isNotEmpty;

                return FilledButton(
                  onPressed: valid
                      ? () =>
                            Navigator.of(sheetContext)
                                .pop(controller.text.trim())
                      : null,
                  child: const Text('Simpan'),
                );
              },
            ),
          ],
        ),
      );
    },
  );

  if (title == null) {
    return;
  }

  final result = await ref.read(noteRepositoryProvider).addNote(title: title);

  if (result.failure != null) {
    messenger.showSnackBar(SnackBar(content: Text(result.failure!.message)));
    return;
  }

  ref.invalidate(notesProvider);
  messenger.showSnackBar(const SnackBar(content: Text('Catatan tersimpan')));
}
