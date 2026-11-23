import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../ai/ai_failures.dart';
import '../../../../routes.dart';
import '../providers/ai_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _dialogOpen = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? value]) {
    final text = (value ?? _inputController.text).trim();
    if (text.isEmpty) {
      return;
    }

    if (value == null) {
      _inputController.clear();
    }

    FocusScope.of(context).unfocus();
    ref.read(chatControllerProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSettings() async {
    await context.push(AppRoutes.aiSettings);
    if (!mounted) {
      return;
    }

    ref.invalidate(aiKeyStatusProvider);
    ref.invalidate(aiUsageStatusProvider);
  }

  Future<void> _showErrorDialog(AiFailure failure) async {
    if (_dialogOpen) {
      return;
    }

    _dialogOpen = true;
    final needsKey = failure is AiMissingKeyFailure || failure is AiAuthFailure;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_dialogTitle(failure)),
          content: Text(failure.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('offline'),
              child: const Text('Mode Offline'),
            ),
            if (failure.canRetry)
              FilledButton.tonal(
                onPressed: () => Navigator.of(dialogContext).pop('retry'),
                child: const Text('Coba Lagi'),
              ),
            if (needsKey)
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop('settings'),
                child: const Text('Atur API Key'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('close'),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );

    _dialogOpen = false;

    if (!mounted) {
      return;
    }

    final controller = ref.read(chatControllerProvider.notifier);

    switch (action) {
      case 'offline':
        await controller.useOfflineFallback();
      case 'retry':
        await controller.retryLast();
      case 'settings':
        controller.clearError();
        await _openSettings();
      default:
        controller.clearError();
    }
  }

  String _dialogTitle(AiFailure failure) {
    return switch (failure) {
      AiMissingKeyFailure() => 'Kunci API Belum Diatur',
      AiQuotaFailure() => 'Kuota AI Habis',
      AiAuthFailure() => 'Kunci API Ditolak',
      AiRateLimitFailure() => 'Layanan AI Sibuk',
      AiNetworkFailure() => 'Koneksi Bermasalah',
      AiServerFailure() => 'Layanan AI Bermasalah',
      _ => 'Layanan AI Sibuk',
    };
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen tidak memicu rebuild layar; hanya efek samping.
    ref.listen<AiFailure?>(chatControllerProvider.select((s) => s.error), (
      previous,
      next,
    ) {
      if (next == null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _showErrorDialog(next);
      });
    });

    ref.listen<int>(
      chatControllerProvider.select(
        (s) => s.messages.isEmpty ? 0 : s.messages.last.text.length,
      ),
      (previous, next) => _scrollToBottom(),
    );

    return Column(
      children: [
        _KeyBannerGate(onSetup: _openSettings),
        Expanded(child: _ChatBody(scrollController: _scrollController)),
        _ChatInputBar(controller: _inputController, onSend: _send),
      ],
    );
  }
}

/// Hanya mendengarkan status kunci API, sehingga chunk streaming tidak
/// membangun ulang banner.
class _KeyBannerGate extends ConsumerWidget {
  const _KeyBannerGate({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missing = ref.watch(
      aiKeyStatusProvider.select(
        (status) => status.hasValue && status.value == null,
      ),
    );

    if (!missing) {
      return const SizedBox.shrink();
    }

    return _KeyBanner(onSetup: onSetup);
  }
}

/// Daftar pesan dipisah agar hanya subtree ini yang dibangun ulang saat
/// token streaming bertambah. Bubble lama memakai instance widget yang sama
/// (memoized) sehingga Flutter melewati update untuk pesan yang tidak berubah.
class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody> {
  List<ChatMessage> _lastMessages = const [];
  List<Widget> _items = const [];

  List<Widget> _itemsFor(List<ChatMessage> messages) {
    if (identical(messages, _lastMessages)) {
      return _items;
    }

    final items = <Widget>[];
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final reusable =
          i < _lastMessages.length &&
          identical(message, _lastMessages[i]) &&
          i < _items.length;

      items.add(
        reusable
            ? _items[i]
            : RepaintBoundary(
                key: ValueKey(i),
                child: _ChatBubble(message: message),
              ),
      );
    }

    _lastMessages = messages;
    _items = items;
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      chatControllerProvider.select((s) => s.messages),
    );
    final isStreaming = ref.watch(
      chatControllerProvider.select((s) => s.isStreaming),
    );
    final items = _itemsFor(messages);

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _EmptyChat(
                  onSuggestion: (text) =>
                      ref.read(chatControllerProvider.notifier).send(text),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) => items[index],
                ),
        ),
        if (isStreaming)
          const RepaintBoundary(child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

/// Input, tombol kirim, dan info kuota hanya bergantung pada status streaming
/// dan kuota; keduanya jarang berubah dibandingkan chunk jawaban.
class _ChatInputBar extends ConsumerWidget {
  const _ChatInputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStreaming = ref.watch(
      chatControllerProvider.select((s) => s.isStreaming),
    );
    final usage = ref.watch(
      aiUsageStatusProvider.select((status) => status.value),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usage == null
                          ? 'AI dapat salah. Periksa informasi penting.'
                          : 'Kuota lokal ${usage.used}/${usage.limit} '
                                '· AI dapat salah. Periksa informasi penting.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaan...',
                      isDense: true,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: isStreaming ? 'Hentikan' : 'Kirim',
                  onPressed: isStreaming
                      ? () => ref.read(chatControllerProvider.notifier).stop()
                      : onSend,
                  icon: Icon(isStreaming ? Icons.stop : Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyBanner extends StatelessWidget {
  const _KeyBanner({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.key_off, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kunci API belum diatur. Fitur AI memerlukan kunci Gemini.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onSetup, child: const Text('Atur')),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});

  final void Function(String) onSuggestion;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Apa itu Campus Notify?',
      'Di mana saya bisa melihat pengumuman?',
      'Bagaimana cara menyimpan catatan?',
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.auto_awesome,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Tanyakan apa saja tentang kampus',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Jawaban dibuat oleh model AI. Data pribadi seperti NIK, nomor '
          'telepon, email, dan alamat disamarkan sebelum dikirim.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in suggestions)
              ActionChip(
                label: Text(suggestion),
                onPressed: () => onSuggestion(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.fromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'Anda' : 'Asisten AI',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUser
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (message.text.isEmpty && message.isStreaming)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Menulis jawaban...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              SelectableText(message.text),
            if (message.source == AiAnswerSource.cache)
              _SourceLabel(icon: Icons.cached, label: 'Dari cache lokal'),
            if (message.source == AiAnswerSource.offline)
              _SourceLabel(
                icon: Icons.offline_bolt_outlined,
                label: 'Mode offline',
              ),
            if (message.redactions > 0)
              _SourceLabel(
                icon: Icons.shield_outlined,
                label:
                    '${message.redactions} data pribadi disamarkan sebelum dikirim',
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
