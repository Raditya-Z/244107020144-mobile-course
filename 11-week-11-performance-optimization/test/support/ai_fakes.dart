import 'package:campus_notify/ai/ai_key_store.dart';
import 'package:campus_notify/ai/ai_storage.dart';

class MemoryAiStorage implements AiStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class FakeAiKeyStore implements AiKeyStore {
  FakeAiKeyStore([this.key]);

  String? key;

  @override
  Future<String?> readKey() async => key;

  @override
  Future<void> saveKey(String value) async {
    key = value.trim();
  }

  @override
  Future<void> clearKey() async {
    key = null;
  }
}
