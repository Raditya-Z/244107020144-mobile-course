import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_providers.dart';

/// Menambah catatan lewat abstraksi NoteRepository (domain), bukan SQLite
/// langsung dari widget. Judul kosong tidak bisa disimpan (validasi minimal
/// mengikuti pola aplikasi Offline Notes Minggu 5/8).
Future<void> showAddNoteSheet(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);

  final title = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _AddNoteSheet(),
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

/// Controller dimiliki State sheet agar ikut dilepas lewat dispose saat
/// sheet ditutup, bukan menunggu GC ketika pengguna berulang kali
/// membuka/menutup sheet.
class _AddNoteSheet extends StatefulWidget {
  const _AddNoteSheet();

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Judul catatan'),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final valid = _controller.text.trim().isNotEmpty;

              return FilledButton(
                onPressed: valid
                    ? () => Navigator.of(context).pop(_controller.text.trim())
                    : null,
                child: const Text('Simpan'),
              );
            },
          ),
        ],
      ),
    );
  }
}
