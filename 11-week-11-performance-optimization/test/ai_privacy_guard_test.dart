import 'package:campus_notify/ai/privacy_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guard = PrivacyGuard();

  test('menyamarkan NIK, nomor telepon, email, dan alamat', () {
    const input =
        'NIK 3201234567890123, HP 081234567890, email budi@example.com, '
        'alamat Jl. Soekarno Hatta 12';

    final result = guard.redact(input);

    expect(result.redactions, 4);
    expect(result.wasRedacted, isTrue);
    expect(result.text, contains('[identitas disamarkan]'));
    expect(result.text, contains('[nomor telepon disamarkan]'));
    expect(result.text, contains('[email disamarkan]'));
    expect(result.text, contains('[alamat disamarkan]'));
    expect(result.text, isNot(contains('3201234567890123')));
    expect(result.text, isNot(contains('081234567890')));
    expect(result.text, isNot(contains('budi@example.com')));
  });

  test('menyamarkan NIK tanpa label identitas', () {
    final result = guard.redact('Nomor KTP 3201234567890123');

    expect(result.text, contains('[NIK disamarkan]'));
    expect(result.text, isNot(contains('3201234567890123')));
  });

  test('menyamarkan label identitas seperti NIM', () {
    final result = guard.redact('NIM: 244107020144');

    expect(result.text, '[identitas disamarkan]');
    expect(result.redactions, 1);
  });

  test('teks biasa tidak berubah', () {
    const input = 'Apa jadwal kuliah hari Senin?';
    final result = guard.redact(input);

    expect(result.text, input);
    expect(result.redactions, 0);
    expect(result.wasRedacted, isFalse);
    expect(guard.hasSensitiveData(input), isFalse);
  });

  test('mendeteksi data sensitif tanpa mengubah teks asli', () {
    const input = 'Hubungi saya di 081234567890';

    expect(guard.hasSensitiveData(input), isTrue);
    expect(input, 'Hubungi saya di 081234567890');
  });
}
