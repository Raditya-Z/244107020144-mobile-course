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
  StatsNotifier({
    this.failureChance,
  });

  final double Function()? failureChance;

  @override
  Future<List<StatItem>> build() async {
    // Simulasi proses mengambil data selama 2 detik.
    await Future<void>.delayed(const Duration(seconds: 2));

    // Menghasilkan angka random antara 0.0 sampai 1.0.
    final chance = failureChance?.call() ?? Random().nextDouble();

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
final AsyncNotifierProvider<StatsNotifier, List<StatItem>> statsProvider =
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