import 'dart:convert';

import 'ai_storage.dart';

class AiResponseCache {
  AiResponseCache({
    required this.storage,
    this.maxEntries = 20,
    this.ttl = const Duration(days: 7),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const storageKey = 'ai_cache';

  final AiStorage storage;
  final int maxEntries;
  final Duration ttl;
  final DateTime Function() _clock;

  Future<String?> read(String prompt) async {
    final entries = await _load();
    final key = _normalize(prompt);
    final entry = entries[key];

    if (entry is! Map) {
      return null;
    }

    final storedAt = DateTime.tryParse(entry['stored_at']?.toString() ?? '');
    if (storedAt == null || _clock().difference(storedAt) > ttl) {
      entries.remove(key);
      await _save(entries);
      return null;
    }

    final answer = entry['answer'];
    return answer is String && answer.isNotEmpty ? answer : null;
  }

  Future<void> write(String prompt, String answer) async {
    if (answer.trim().isEmpty) {
      return;
    }

    final entries = await _load();
    final key = _normalize(prompt);

    entries.remove(key);
    entries[key] = {'answer': answer, 'stored_at': _clock().toIso8601String()};

    while (entries.length > maxEntries) {
      entries.remove(entries.keys.first);
    }

    await _save(entries);
  }

  String _normalize(String prompt) {
    return prompt.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<Map<String, dynamic>> _load() async {
    final raw = await storage.read(storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final data = jsonDecode(raw);
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Future<void> _save(Map<String, dynamic> entries) {
    return storage.write(storageKey, jsonEncode(entries));
  }
}
