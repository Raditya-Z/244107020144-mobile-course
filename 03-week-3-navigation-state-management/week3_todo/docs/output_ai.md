# Output Awal AI

AI yang digunakan: GitHub Copilot

Berikut adalah output awal yang diberikan AI berdasarkan prompt pada `prompt.md`.

## StatsPage


```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model untuk satu data statistik.
class StatItem {
  final String title;
  final int value;

  const StatItem({
    required this.title,
    required this.value,
  });
}

/// AsyncNotifier untuk mengambil data statistik.
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  /// Fungsi ini dibuat agar proses random dapat diganti saat testing.
  StatsNotifier({double Function()? failureChance})
      : _failureChance = failureChance;

  final double Function()? _failureChance;

  @override
  Future<List<StatItem>> build() async {
    // Simulasi proses mengambil data selama 2 detik.
    await Future<void>.delayed(const Duration(seconds: 2));

    // Menghasilkan angka random antara 0.0 sampai 1.0.
    final chance = _failureChance?.call() ?? Random().nextDouble();

    // Jika angka kurang dari 0.3, proses dianggap gagal.
    if (chance < 0.3) {
      throw Exception('Gagal mengambil data statistik.');
    }

    // Data dikembalikan jika proses berhasil.
    return const [
      StatItem(title: 'Total Pengguna', value: 1200),
      StatItem(title: 'Pesanan Selesai', value: 845),
      StatItem(title: 'Pendapatan', value: 32500000),
    ];
  }
}

/// Provider yang menyediakan state statistik.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);

/// Halaman statistik menggunakan ConsumerWidget.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state dari statsProvider.
    final statsState = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: statsState.when(
        // Ditampilkan selama proses delay berlangsung.
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Ditampilkan jika terjadi error.
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                // Provider dibuat ulang untuk mengambil data kembali.
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),

        // Ditampilkan jika data berhasil diperoleh.
        data: (stats) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];

            return Card(
              child: ListTile(
                title: Text(item.title),
                trailing: Text(
                  item.value.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## Unit Test


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/pages/stats_page.dart';

void main() {
  test('notifier menghasilkan tiga data statistik', () async {
    final container = ProviderContainer(
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
      overrides: [
        // Nilai 0.1 berada di bawah 0.3 sehingga menghasilkan error.
        statsProvider.overrideWith(
          () => StatsNotifier(failureChance: () => 0.1),
        ),
      ],
    );

    addTearDown(container.dispose);

    expect(
      () => container.read(statsProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
```

## Catatan

Output pada file ini merupakan hasil awal AI sebelum dilakukan verifikasi dan perbaikan.
