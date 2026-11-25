sealed class AiFailure implements Exception {
  const AiFailure(this.message, {this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  String toString() => message;
}

class AiMissingKeyFailure extends AiFailure {
  const AiMissingKeyFailure()
    : super(
        'Kunci API belum diatur. Buka Pengaturan AI untuk menambahkan kunci.',
        canRetry: false,
      );
}

class AiQuotaFailure extends AiFailure {
  AiQuotaFailure(this.limit)
    : super(
        'Kuota AI lokal hari ini ($limit permintaan) sudah habis. '
        'Coba lagi besok atau gunakan mode offline.',
        canRetry: false,
      );

  final int limit;
}

class AiAuthFailure extends AiFailure {
  const AiAuthFailure()
    : super(
        'Kunci API ditolak. Periksa kembali kunci di Pengaturan AI.',
        canRetry: false,
      );
}

class AiRateLimitFailure extends AiFailure {
  const AiRateLimitFailure()
    : super(
        'Layanan AI sedang sibuk atau batas permintaan tercapai. '
        'Coba lagi beberapa saat lagi.',
      );
}

class AiNetworkFailure extends AiFailure {
  const AiNetworkFailure([
    super.message =
        'Tidak dapat terhubung ke layanan AI. Periksa koneksi internet.',
  ]);
}

class AiServerFailure extends AiFailure {
  const AiServerFailure([
    super.message = 'Layanan AI sedang bermasalah. Coba lagi nanti.',
  ]);
}

class AiInvalidRequestFailure extends AiFailure {
  // ignore: use_super_parameters
  const AiInvalidRequestFailure([
    String message = 'Permintaan AI tidak valid. Periksa kembali input.',
  ]) : super(message, canRetry: false);
}

class AiInvalidResponseFailure extends AiFailure {
  const AiInvalidResponseFailure([
    super.message = 'Respons AI tidak dapat dibaca. Coba lagi.',
  ]);
}

class AiFileTooLargeFailure extends AiFailure {
  const AiFileTooLargeFailure()
    : super(
        'Ukuran file terlalu besar. Gunakan gambar atau rekaman yang lebih kecil.',
        canRetry: false,
      );
}

class AiPermissionFailure extends AiFailure {
  // ignore: use_super_parameters
  const AiPermissionFailure([
    String message =
        'Izin mikrofon diperlukan untuk merekam suara. '
        'Aktifkan izin mikrofon pada pengaturan aplikasi.',
  ]) : super(message, canRetry: false);
}
