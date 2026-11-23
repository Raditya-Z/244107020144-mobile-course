import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ai/ai_cache.dart';
import '../../../../ai/ai_failures.dart';
import '../../../../ai/ai_fallback.dart';
import '../../../../ai/ai_key_store.dart';
import '../../../../ai/ai_service.dart';
import '../../../../ai/ai_storage.dart';
import '../../../../ai/ai_usage_limiter.dart';
import '../../../../ai/privacy_guard.dart';

final aiStorageProvider = Provider<AiStorage>((ref) {
  return const SecureAiStorage();
});

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) {
  return SecureAiKeyStore(ref.watch(aiStorageProvider));
});

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService(keyStore: ref.watch(aiKeyStoreProvider));
  ref.onDispose(service.close);
  return service;
});

final aiUsageProvider = Provider<AiUsageLimiter>((ref) {
  return AiUsageLimiter(storage: ref.watch(aiStorageProvider));
});

final aiCacheProvider = Provider<AiResponseCache>((ref) {
  return AiResponseCache(storage: ref.watch(aiStorageProvider));
});

final aiFallbackProvider = Provider<AiFallback>((ref) {
  return const AiFallback();
});

final aiKeyStatusProvider = FutureProvider<String?>((ref) {
  return ref.watch(aiKeyStoreProvider).readKey();
});

final aiUsageStatusProvider = FutureProvider<AiUsage>((ref) {
  return ref.watch(aiUsageProvider).current();
});

enum AiAnswerSource { ai, cache, offline }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    this.source,
    this.isStreaming = false,
    this.redactions = 0,
  });

  final String text;
  final bool fromUser;
  final AiAnswerSource? source;
  final bool isStreaming;
  final int redactions;

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      text: text ?? this.text,
      fromUser: fromUser,
      source: source,
      isStreaming: isStreaming ?? this.isStreaming,
      redactions: redactions,
    );
  }
}

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
    this.lastQuestion,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final AiFailure? error;
  final String? lastQuestion;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    AiFailure? error,
    bool clearError = false,
    String? lastQuestion,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      lastQuestion: lastQuestion ?? this.lastQuestion,
    );
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  static const _privacy = PrivacyGuard();
  bool _stopRequested = false;

  @override
  ChatState build() => const ChatState();

  Future<void> send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || state.isStreaming) {
      return;
    }

    final history = _history(state.messages);
    final safeQuestion = _privacy.redact(question);
    _stopRequested = false;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          text: question,
          fromUser: true,
          redactions: safeQuestion.redactions,
        ),
      ],
      isStreaming: true,
      clearError: true,
      lastQuestion: question,
    );

    final key = await ref.read(aiKeyStoreProvider).readKey();
    if (key == null) {
      state = state.copyWith(
        isStreaming: false,
        error: const AiMissingKeyFailure(),
      );
      return;
    }

    final cache = ref.read(aiCacheProvider);
    final cached = await cache.read(safeQuestion.text);
    if (cached != null && cached.isNotEmpty) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: cached,
            fromUser: false,
            source: AiAnswerSource.cache,
          ),
        ],
        isStreaming: false,
      );
      return;
    }

    try {
      await ref.read(aiUsageProvider).consume();
      ref.invalidate(aiUsageStatusProvider);
    } on AiFailure catch (failure) {
      state = state.copyWith(isStreaming: false, error: failure);
      return;
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        const ChatMessage(
          text: '',
          fromUser: false,
          source: AiAnswerSource.ai,
          isStreaming: true,
        ),
      ],
    );

    final buffer = StringBuffer();

    try {
      await for (final chunk
          in ref
              .read(aiServiceProvider)
              .askStream(question, history: history)) {
        if (_stopRequested) {
          break;
        }

        buffer.write(chunk);
        _updateAssistant(buffer.toString(), isStreaming: true);
      }

      final answer = buffer.toString().trim();

      if (answer.isEmpty) {
        _removeEmptyAssistant();
        state = state.copyWith(isStreaming: false, clearError: true);
        return;
      }

      _updateAssistant(answer, isStreaming: false);
      await cache.write(safeQuestion.text, answer);
      state = state.copyWith(isStreaming: false, clearError: true);
      ref.invalidate(aiUsageStatusProvider);
    } on AiFailure catch (failure) {
      _removeEmptyAssistant();
      state = state.copyWith(isStreaming: false, error: failure);
      ref.invalidate(aiUsageStatusProvider);
    } catch (_) {
      _removeEmptyAssistant();
      state = state.copyWith(
        isStreaming: false,
        error: const AiServerFailure(
          'Terjadi kesalahan saat memproses jawaban AI. Coba lagi.',
        ),
      );
    }
  }

  void stop() {
    _stopRequested = true;
  }

  void clearError() {
    if (state.error == null) {
      return;
    }

    state = state.copyWith(clearError: true);
  }

  Future<void> retryLast() async {
    final question = state.lastQuestion;
    if (question == null) {
      clearError();
      return;
    }

    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.fromUser) {
      messages.removeLast();
    }

    state = state.copyWith(
      messages: messages,
      isStreaming: false,
      clearError: true,
    );

    await send(question);
  }

  Future<void> useOfflineFallback() async {
    final question = state.lastQuestion;
    if (question == null) {
      clearError();
      return;
    }

    final safeQuestion = _privacy.redact(question).text;
    final cached = await ref.read(aiCacheProvider).read(safeQuestion);
    final local = ref.read(aiFallbackProvider).answer(question);

    final text =
        cached ??
        local ??
        'Layanan AI sedang tidak tersedia. Periksa koneksi internet, '
            'lalu coba lagi atau gunakan fitur lokal aplikasi.';

    final source = cached != null
        ? AiAnswerSource.cache
        : AiAnswerSource.offline;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: text, fromUser: false, source: source),
      ],
      clearError: true,
    );
  }

  void _updateAssistant(String text, {required bool isStreaming}) {
    if (state.messages.isEmpty || state.messages.last.fromUser) {
      return;
    }

    final messages = [...state.messages];
    messages[messages.length - 1] = messages.last.copyWith(
      text: text,
      isStreaming: isStreaming,
    );
    state = state.copyWith(messages: messages);
  }

  void _removeEmptyAssistant() {
    if (state.messages.isEmpty || state.messages.last.fromUser) {
      return;
    }

    if (state.messages.last.text.trim().isEmpty) {
      final messages = [...state.messages]..removeLast();
      state = state.copyWith(messages: messages);
    }
  }

  List<AiTurn> _history(List<ChatMessage> messages) {
    final usable = messages
        .where((message) => message.text.trim().isNotEmpty)
        .toList();

    final recent = usable.length > 6
        ? usable.sublist(usable.length - 6)
        : usable;

    return recent
        .map(
          (message) => AiTurn(
            role: message.fromUser ? 'user' : 'model',
            text: message.text,
          ),
        )
        .toList();
  }
}
