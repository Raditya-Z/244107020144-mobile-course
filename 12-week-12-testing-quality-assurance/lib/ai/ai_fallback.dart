class AiFallback {
  const AiFallback();

  String? answer(String question) {
    final query = question.toLowerCase();

    if (query.contains('jadwal') || query.contains('kuliah')) {
      return 'Jadwal lengkap tidak tersedia di perangkat. Buka pengumuman '
          'kampus atau coba lagi saat layanan AI dapat dihubungi.';
    }

    if (query.contains('catatan') || query.contains('notes')) {
      return 'Catatan disimpan secara lokal dan tetap dapat dibuka dari '
          'halaman Catatan tanpa koneksi internet.';
    }

    if (query.contains('pengumuman')) {
      return 'Pengumuman kampus dapat dibuka dari halaman utama aplikasi. '
          'Layanan AI tidak diperlukan untuk membaca pengumuman.';
    }

    if (query.contains('campus notify') || query.contains('aplikasi')) {
      return 'Campus Notify membantu membaca pengumuman, menyimpan catatan '
          'lokal, dan memakai fitur AI saat koneksi tersedia.';
    }

    return null;
  }
}
