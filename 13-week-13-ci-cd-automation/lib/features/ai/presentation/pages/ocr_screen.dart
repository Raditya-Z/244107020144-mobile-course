import 'package:material_ui/material_ui.dart';

import '../widgets/image_ai_panel.dart';

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ImageAiPanel(
      heading: 'OCR — Ekstrak Teks',
      description:
          'Pilih foto dokumen, papan pengumuman, atau struk. Teks pada gambar '
          'akan diekstrak oleh model AI.',
      actionLabel: 'Ekstrak Teks',
      resultTitle: 'Hasil OCR',
      icon: Icons.document_scanner_outlined,
      action: (service, bytes, mimeType) {
        return service.recognizeText(bytes, mimeType: mimeType);
      },
    );
  }
}
