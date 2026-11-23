import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../ai/ai_key_store.dart';
import '../../../../ai/ai_usage_limiter.dart';
import '../providers/ai_providers.dart';
import '../widgets/ai_widgets.dart';

class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final _keyController = TextEditingController();

  String? _maskedKey;
  String? _error;
  bool _saving = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final key = await ref.read(aiKeyStoreProvider).readKey();
    if (!mounted) {
      return;
    }

    setState(() {
      _maskedKey = key == null ? null : maskApiKey(key);
    });
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      setState(() => _error = 'Kunci API tidak boleh kosong.');
      return;
    }

    if (key.length < 20) {
      setState(() => _error = 'Kunci API terlihat tidak valid.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(aiKeyStoreProvider).saveKey(key);
      ref.invalidate(aiKeyStatusProvider);
      ref.invalidate(aiUsageStatusProvider);
      await _loadKey();

      if (!mounted) {
        return;
      }

      _keyController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kunci API disimpan.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Kunci API gagal disimpan. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _clearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus kunci API?'),
          content: const Text(
            'Fitur AI tidak dapat digunakan sampai kunci baru ditambahkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _clearing = true);

    try {
      await ref.read(aiKeyStoreProvider).clearKey();
      ref.invalidate(aiKeyStatusProvider);
      ref.invalidate(aiUsageStatusProvider);
      await _loadKey();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kunci API dihapus.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Kunci API gagal dihapus. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(aiUsageStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AiNotice(
            text:
                'Kunci API disimpan di secure storage perangkat dan tidak '
                'pernah ditulis di kode sumber atau dikirim ke server lain.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kunci API Gemini',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Buat kunci di Google AI Studio, lalu tempelkan di bawah.',
                  ),
                  const SizedBox(height: 4),
                  const SelectableText(
                    'https://aistudio.google.com/app/apikey',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(
                      labelText: 'Kunci API baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_maskedKey != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Kunci tersimpan: $_maskedKey')),
                        TextButton(
                          onPressed: _clearing ? null : _clearKey,
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveKey,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan Kunci'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biaya dan Kuota',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  usageAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) =>
                        const Text('Kuota lokal tidak dapat dibaca.'),
                    data: (usage) => _UsageContent(usage: usage),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privasi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const _PrivacyItem(
                    icon: Icons.shield_outlined,
                    text:
                        'NIK, nomor telepon, email, dan alamat disamarkan '
                        'sebelum teks dikirim ke AI.',
                  ),
                  const _PrivacyItem(
                    icon: Icons.image_outlined,
                    text:
                        'Gambar dan audio hanya dikirim saat Anda menekan '
                        'tombol analisis atau transkripsi.',
                  ),
                  const _PrivacyItem(
                    icon: Icons.cached,
                    text:
                        'Jawaban terakhir disimpan di cache lokal selama 7 '
                        'hari untuk mengurangi biaya.',
                  ),
                  const _PrivacyItem(
                    icon: Icons.no_accounts_outlined,
                    text: 'Isi percakapan tidak ditulis ke log aplikasi.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('gemini-3.5-flash-lite (Gemini API)'),
                  const SizedBox(height: 4),
                  Text(
                    'Kunci dikirim melalui header x-goog-api-key, bukan di URL.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageContent extends StatelessWidget {
  const _UsageContent({required this.usage});

  final AiUsage usage;

  @override
  Widget build(BuildContext context) {
    final ratio = usage.limit == 0
        ? 0.0
        : (usage.used / usage.limit).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${usage.used} dari ${usage.limit} permintaan terpakai '
          '(reset ${usage.date}).',
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: ratio),
        const SizedBox(height: 8),
        Text(
          'Batas ini dihitung lokal untuk mencegah biaya tak terduga. '
          'Kuota dan tarif dari provider tetap berlaku.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
