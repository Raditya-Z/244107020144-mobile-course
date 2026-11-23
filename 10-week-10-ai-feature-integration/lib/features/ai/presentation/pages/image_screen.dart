import 'package:material_ui/material_ui.dart';

import '../widgets/image_ai_panel.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ImageAiPanel(
      heading: 'Image Understanding',
      description:
          'Pilih gambar lalu minta deskripsi singkat. Berguna untuk memahami '
          'objek atau isi gambar.',
      actionLabel: 'Jelaskan Gambar',
      resultTitle: 'Deskripsi Gambar',
      icon: Icons.image_search_outlined,
      action: (service, bytes, mimeType) {
        return service.describeImage(bytes, mimeType: mimeType);
      },
    );
  }
}
