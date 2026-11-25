import 'package:campus_notify/ai/ai_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ai_fakes.dart';

void main() {
  test('jawaban tersimpan dapat dibaca dengan kunci ternormalisasi', () async {
    final cache = AiResponseCache(storage: MemoryAiStorage());

    await cache.write('Halo   Dunia', 'Jawaban tersimpan');

    expect(await cache.read('halo dunia'), 'Jawaban tersimpan');
    expect(await cache.read('HALO DUNIA'), 'Jawaban tersimpan');
  });

  test('entri kedaluwarsa tidak dikembalikan', () async {
    final storage = MemoryAiStorage();
    var now = DateTime(2026, 11, 24);
    final cache = AiResponseCache(
      storage: storage,
      ttl: const Duration(days: 1),
      clock: () => now,
    );

    await cache.write('Halo', 'Jawaban');
    expect(await cache.read('Halo'), 'Jawaban');

    now = now.add(const Duration(days: 2));
    expect(await cache.read('Halo'), isNull);
    expect(storage.values[AiResponseCache.storageKey], '{}');
  });

  test('jumlah entri dibatasi dan entri lama dihapus', () async {
    final cache = AiResponseCache(storage: MemoryAiStorage(), maxEntries: 2);

    await cache.write('satu', 'A');
    await cache.write('dua', 'B');
    await cache.write('tiga', 'C');

    expect(await cache.read('satu'), isNull);
    expect(await cache.read('dua'), 'B');
    expect(await cache.read('tiga'), 'C');
  });

  test('jawaban kosong tidak disimpan', () async {
    final cache = AiResponseCache(storage: MemoryAiStorage());

    await cache.write('Halo', '   ');

    expect(await cache.read('Halo'), isNull);
  });
}
