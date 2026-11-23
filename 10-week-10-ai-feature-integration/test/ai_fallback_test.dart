import 'package:campus_notify/ai/ai_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fallback = AiFallback();

  test('menjawab pertanyaan jadwal dari data lokal', () {
    expect(fallback.answer('Apa jadwal kuliah hari Senin?'), isNotNull);
  });

  test('menjawab pertanyaan catatan dari data lokal', () {
    expect(fallback.answer('Di mana catatan saya?'), isNotNull);
  });

  test('menjawab pertanyaan tentang Campus Notify', () {
    final answer = fallback.answer('Apa itu Campus Notify?');

    expect(answer, isNotNull);
    expect(answer, contains('Campus Notify'));
  });

  test('pertanyaan di luar cakupan mengembalikan null', () {
    expect(fallback.answer('Resep rendang'), isNull);
  });
}
