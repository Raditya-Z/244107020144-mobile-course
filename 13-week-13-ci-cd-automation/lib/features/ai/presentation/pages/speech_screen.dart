import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../ai/ai_failures.dart';
import '../../../../routes.dart';
import '../providers/ai_providers.dart';
import '../widgets/ai_dialogs.dart';
import '../widgets/ai_widgets.dart';

class SpeechScreen extends ConsumerStatefulWidget {
  const SpeechScreen({super.key});

  @override
  ConsumerState<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends ConsumerState<SpeechScreen> {
  static const _maxSeconds = 60;
  static const _config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  );

  final _recorder = AudioRecorder();

  Timer? _timer;
  Uint8List? _audio;
  String? _result;
  AiFailure? _error;
  bool _recording = false;
  bool _transcribing = false;
  int _seconds = 0;
  int _audioSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_recording || _transcribing) {
      return;
    }

    setState(() {
      _error = null;
      _result = null;
      _audio = null;
      _seconds = 0;
    });

    try {
      final permitted = await _recorder.hasPermission();
      if (!mounted) {
        return;
      }

      if (!permitted) {
        setState(() => _error = const AiPermissionFailure());
        return;
      }

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/ai_speech_'
          '${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(_config, path: path);

      if (!mounted) {
        await _recorder.stop();
        return;
      }

      setState(() {
        _recording = true;
        _seconds = 0;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_seconds >= _maxSeconds - 1) {
          unawaited(_stop());
          return;
        }

        setState(() => _seconds++);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = const AiServerFailure(
          'Perekaman gagal dimulai. Periksa mikrofon lalu coba lagi.',
        );
      });
    }
  }

  Future<void> _stop() async {
    if (!_recording) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    setState(() => _recording = false);

    try {
      final path = await _recorder.stop();
      if (!mounted) {
        return;
      }

      if (path == null) {
        setState(() {
          _error = const AiServerFailure(
            'Hasil rekaman tidak tersedia. Coba rekam ulang.',
          );
        });
        return;
      }

      final bytes = await File(path).readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _audio = bytes;
        _audioSeconds = _seconds;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = const AiServerFailure(
          'Rekaman tidak dapat dibaca. Coba rekam ulang.',
        );
      });
    }
  }

  Future<void> _transcribe() async {
    final audio = _audio;
    if (audio == null || _transcribing) {
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
      _transcribing = true;
      _error = null;
      _result = null;
    });

    try {
      final text = await ref
          .read(aiServiceProvider)
          .speechToText(audio, mimeType: 'audio/wav');

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
        setState(() => _transcribing = false);
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

  String _format(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = _error;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AiNotice(
          text:
              'Audio direkam di perangkat dan hanya dikirim saat Anda '
              'menekan Transkripsi. Hindari menyebut NIK, nomor telepon, '
              'atau alamat.',
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: _recording ? scheme.error : scheme.primary,
                foregroundColor: _recording ? scheme.onError : scheme.onPrimary,
              ),
              onPressed: _recording ? _stop : (_transcribing ? null : _start),
              child: Icon(_recording ? Icons.stop : Icons.mic, size: 56),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _recording
                ? 'Merekam ${_format(_seconds)}'
                : _audio == null
                ? 'Ketuk untuk merekam'
                : 'Rekaman siap (${_format(_audioSeconds)})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _recording
                ? 'Ketuk lagi untuk berhenti. Maksimal $_maxSeconds detik.'
                : 'Rekaman maksimal $_maxSeconds detik.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (_recording) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _seconds / _maxSeconds),
        ],
        if (_audio != null && !_recording) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _transcribing ? null : _start,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rekam Ulang'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _transcribing ? null : _transcribe,
                  icon: const Icon(Icons.transcribe),
                  label: const Text('Transkripsi'),
                ),
              ),
            ],
          ),
        ],
        if (_transcribing) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Mengirim audio ke layanan AI...'),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          AiErrorCard(
            message: error.message,
            onRetry: error.canRetry && _audio != null ? _transcribe : null,
            onSetupKey: error is AiAuthFailure ? _openSettings : null,
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          AiResultCard(title: 'Transkrip', text: _result!),
        ],
      ],
    );
  }
}
