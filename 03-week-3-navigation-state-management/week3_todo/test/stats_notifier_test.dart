import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/pages/stats_page.dart';

void main() {
  test('notifier menghasilkan tiga data statistik', () async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        // Nilai 0.9 memastikan test selalu berhasil.
        statsProvider.overrideWith(
          () => StatsNotifier(failureChance: () => 0.9),
        ),
      ],
    );

    addTearDown(container.dispose);

    // Menunggu proses asynchronous selesai.
    final result = await container.read(statsProvider.future);

    expect(result.length, 3);
    expect(result[0].title, 'Total Pengguna');
    expect(result[1].title, 'Pesanan Selesai');
    expect(result[2].title, 'Pendapatan');
  });

  test('notifier menghasilkan error ketika pengambilan data gagal', () async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        // Nilai 0.1 berada di bawah 0.3 sehingga menghasilkan error.
        statsProvider.overrideWith(
          () => StatsNotifier(failureChance: () => 0.1),
        ),
      ],
    );

    addTearDown(container.dispose);

    await expectLater(
      container.read(statsProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}