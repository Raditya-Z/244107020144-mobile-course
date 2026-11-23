import 'package:campus_notify/ai/ai_failures.dart';
import 'package:campus_notify/ai/ai_usage_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ai_fakes.dart';

void main() {
  test('kuota habis setelah batas harian tercapai', () async {
    final storage = MemoryAiStorage();
    final limiter = AiUsageLimiter(
      storage: storage,
      dailyLimit: 2,
      clock: () => DateTime(2026, 11, 24),
    );

    final first = await limiter.consume();
    final second = await limiter.consume();

    expect(first.used, 1);
    expect(second.used, 2);
    expect(second.remaining, 0);
    expect(limiter.consume(), throwsA(isA<AiQuotaFailure>()));
  });

  test('kuota direset pada hari berikutnya', () async {
    final storage = MemoryAiStorage();
    var now = DateTime(2026, 11, 24);
    final limiter = AiUsageLimiter(
      storage: storage,
      dailyLimit: 1,
      clock: () => now,
    );

    await limiter.consume();
    expect(limiter.consume(), throwsA(isA<AiQuotaFailure>()));

    now = DateTime(2026, 11, 25);
    final nextDay = await limiter.current();

    expect(nextDay.used, 0);
    expect(nextDay.date, '2026-11-25');
    expect((await limiter.consume()).used, 1);
  });

  test('data kuota rusak dianggap kosong', () async {
    final storage = MemoryAiStorage();
    storage.values[AiUsageLimiter.storageKey] = 'bukan-json';

    final limiter = AiUsageLimiter(
      storage: storage,
      dailyLimit: 5,
      clock: () => DateTime(2026, 11, 24),
    );

    final usage = await limiter.current();
    expect(usage.used, 0);
    expect(usage.remaining, 5);
  });
}
