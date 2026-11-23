import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../ai/ai_failures.dart';
import '../../../../ai/ai_service.dart';
import '../../../../routes.dart';
import '../providers/ai_providers.dart';
import '../widgets/ai_dialogs.dart';
import '../widgets/ai_widgets.dart';

typedef ImageAiAction = Future<String> Function(
  AiService service,
  Uint8List bytes,
  String mimeType,
);

class ImageAiPanel extends ConsumerStatefulWidget {
  const ImageAiPanel({
    super.key,
    required this.heading,
    required this.description,
    required this.actionLabel,
    required this.resultTitle,
    required this.icon,
    required this.action,
  });

  final String heading;
  final String description;
  final String actionLabel;
  final String resultTitle;
  final IconData icon;
  final ImageAiAction action;

  @override
  ConsumerState<ImageAiPanel> createState() => _ImageAiPanelState();
}

class _ImageAiPanelState extends ConsumerState<ImageAiPanel> {
  final _picker = ImagePicker();

  Uint8List? _bytes;
  String _mimeType = 'image/jpeg';
  String? _fileName;
  String? _result;
  AiFailure? _error;
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _bytes = bytes;
        _mimeType = _mimeTypeFor(file);
        _fileName = file.name;
        _result = null;
        _error = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = const AiInvalidRequestFailure(
          'Gambar tidak dapat dibuka. Coba pilih gambar lain.',
        );
      });
    }
  }

  String _mimeTypeFor(XFile file) {
    final type = file.mimeType;
    if (type != null && type.isNotEmpty) {
      return type;
    }

    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.webp')) {
      return 'image/webp';
    }
    if (name.endsWith('.heic')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<void> _run() async {
    final bytes = _bytes;
    if (bytes == null || _loading) {
      return;
    }

    final key = await ref.read(aiKeyStoreProvider).readKey();
    if (!mounted) {
      return;
    }

    if (key == null) {
      await showMissingKeyDialog(context);
      return;
    }

    try {
      await ref.read(aiUsageProvider).consume();
      ref.invalidate(aiUsageStatusProvider);
    } on AiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _error = failure);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final text = await widget.action(
        ref.read(aiServiceProvider),
        bytes,
        _mimeType,
      );

      if (!mounted) {
        return;
      }

      setState(() => _result = text);
    } on AiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _error = failure);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = const AiServerFailure());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openSettings() async {
    await context.push(AppRoutes.aiSettings);
    if (!mounted) {
      return;
    }

    ref.invalidate(aiKeyStatusProvider);
    ref.invalidate(aiUsageStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    // Batasi resolusi decode agar gambar 1600 px tidak menghabiskan memori
    // padahal hanya ditampilkan selebar layar.
    final imageCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AiNotice(
          text:
              'Gambar hanya dikirim ke Gemini API ketika Anda menekan '
              '"${widget.actionLabel}". Jangan unggah dokumen yang memuat '
              'NIK atau data pribadi sensitif.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.heading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(widget.description),
        const SizedBox(height: 12),
        if (_bytes == null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 8),
                const Text('Belum ada gambar dipilih.'),
              ],
            ),
          )
        else
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _bytes!,
                cacheWidth: imageCacheWidth,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _fileName!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galeri'),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Kamera'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _bytes == null || _loading ? null : _run,
            icon: Icon(widget.icon),
            label: Text(widget.actionLabel),
          ),
        ),
        if (_loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Mengirim gambar ke layanan AI...'),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          AiErrorCard(
            message: error.message,
            onRetry: error.canRetry ? _run : null,
            onSetupKey: error is AiAuthFailure ? _openSettings : null,
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          AiResultCard(title: widget.resultTitle, text: _result!),
        ],
      ],
    );
  }
}
