import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../routes.dart';

Future<void> showMissingKeyDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Kunci API Belum Diatur'),
        content: const Text(
          'Fitur AI memerlukan kunci Gemini API. Tambahkan kunci di '
          'Pengaturan AI. Kunci disimpan di secure storage perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(AppRoutes.aiSettings);
            },
            child: const Text('Atur API Key'),
          ),
        ],
      );
    },
  );
}
