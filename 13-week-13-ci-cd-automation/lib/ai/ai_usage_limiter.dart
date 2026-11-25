import 'dart:convert';

import 'ai_failures.dart';
import 'ai_storage.dart';

class AiUsage {
  const AiUsage({required this.used, required this.limit, required this.date});

  final int used;
  final int limit;
  final String date;

  int get remaining => (limit - used).clamp(0, limit);
}

class AiUsageLimiter {
  AiUsageLimiter({
    required this.storage,
    this.dailyLimit = 20,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const storageKey = 'ai_usage';

  final AiStorage storage;
  final int dailyLimit;
  final DateTime Function() _clock;

  Future<AiUsage> current() async {
    final today = _day(_clock());
    final raw = await storage.read(storageKey);

    if (raw == null || raw.isEmpty) {
      return AiUsage(used: 0, limit: dailyLimit, date: today);
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['date'] != today) {
        return AiUsage(used: 0, limit: dailyLimit, date: today);
      }

      final used = (data['count'] as num?)?.toInt() ?? 0;
      return AiUsage(used: used, limit: dailyLimit, date: today);
    } on FormatException {
      return AiUsage(used: 0, limit: dailyLimit, date: today);
    }
  }

  Future<AiUsage> consume() async {
    final usage = await current();

    if (usage.used >= dailyLimit) {
      throw AiQuotaFailure(dailyLimit);
    }

    final next = AiUsage(
      used: usage.used + 1,
      limit: dailyLimit,
      date: usage.date,
    );

    await storage.write(
      storageKey,
      jsonEncode({'date': next.date, 'count': next.used}),
    );

    return next;
  }

  String _day(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
