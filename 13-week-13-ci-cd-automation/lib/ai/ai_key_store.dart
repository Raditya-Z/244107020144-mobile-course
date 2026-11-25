import 'ai_storage.dart';

abstract interface class AiKeyStore {
  Future<String?> readKey();

  Future<void> saveKey(String key);

  Future<void> clearKey();
}

class SecureAiKeyStore implements AiKeyStore {
  SecureAiKeyStore(this._storage);

  static const storageKey = 'ai_api_key';

  final AiStorage _storage;

  @override
  Future<String?> readKey() async {
    final value = await _storage.read(storageKey);
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  @override
  Future<void> saveKey(String key) async {
    await _storage.write(storageKey, key.trim());
  }

  @override
  Future<void> clearKey() => _storage.delete(storageKey);
}

String maskApiKey(String key) {
  if (key.length <= 4) {
    return '••••';
  }

  return '••••${key.substring(key.length - 4)}';
}
