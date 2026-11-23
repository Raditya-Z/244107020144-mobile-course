import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_failures.dart';
import 'ai_key_store.dart';
import 'privacy_guard.dart';

class AiTurn {
  const AiTurn({required this.role, required this.text});

  final String role;
  final String text;
}

class AiService {
  AiService({
    required this.keyStore,
    http.Client? client,
    this.model = 'gemini-3.5-flash-lite',
    PrivacyGuard privacyGuard = const PrivacyGuard(),
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _privacy = privacyGuard;

  static const systemPrompt =
      'Kamu adalah asisten kampus Campus Notify. Jawab dalam Bahasa Indonesia '
      'yang ramah dan singkat, maksimal 2 kalimat. Jangan meminta atau '
      'mengulang data pribadi seperti NIK, nomor telepon, alamat, atau email. '
      'Jika informasi tidak tersedia, katakan dengan jujur dan sarankan '
      'menghubungi admin kampus.';

  static const maxInlineBytes = 6 * 1024 * 1024;

  static const _ocrPrompt =
      'Ekstrak seluruh teks yang terlihat pada gambar. Pertahankan urutan '
      'baris. Jika tidak ada teks, jawab "Tidak ada teks yang terdeteksi." '
      'Jangan menambahkan penjelasan lain.';
  static const _imagePrompt =
      'Jelaskan isi gambar ini secara singkat dalam Bahasa Indonesia, maksimal '
      '3 kalimat. Sebutkan objek utama dan konteks yang terlihat.';
  static const _speechPrompt =
      'Transkripsikan seluruh ucapan pada audio ini ke dalam Bahasa Indonesia. '
      'Tulis hanya transkrip, tanpa penjelasan tambahan.';

  final AiKeyStore keyStore;
  final http.Client _client;
  final bool _ownsClient;
  final PrivacyGuard _privacy;
  final Duration timeout;
  final String model;

  Future<String> ask(String question, {List<AiTurn> history = const []}) async {
    final key = await _requireKey();
    final safeQuestion = _privacy.redact(question).text;
    final body = _textBody(safeQuestion, history);
    final data = await _post(key, 'generateContent', body);
    final text = _extractText(data);

    if (text.isEmpty) {
      throw const AiInvalidResponseFailure();
    }

    return text;
  }

  Stream<String> askStream(
    String question, {
    List<AiTurn> history = const [],
  }) async* {
    final key = await _requireKey();
    final safeQuestion = _privacy.redact(question).text;
    final body = _textBody(safeQuestion, history);

    final request =
        http.Request('POST', _uri('streamGenerateContent', stream: true))
          ..headers.addAll(_headers(key))
          ..body = jsonEncode(body);

    http.StreamedResponse response;

    try {
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw const AiNetworkFailure(
        'Permintaan AI melewati batas waktu. Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException {
      throw const AiNetworkFailure();
    }

    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw _failureForStatus(response.statusCode);
    }

    try {
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(timeout);

      await for (final line in lines) {
        if (!line.startsWith('data:')) {
          continue;
        }

        final payload = line.substring(5).trim();
        if (payload.isEmpty) {
          continue;
        }

        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final text = _extractText(decoded, trim: false);
        if (text.isNotEmpty) {
          yield text;
        }
      }
    } on TimeoutException {
      throw const AiNetworkFailure(
        'Respons AI melewati batas waktu. Coba lagi.',
      );
    } on http.ClientException {
      throw const AiNetworkFailure();
    } on FormatException {
      throw const AiInvalidResponseFailure();
    }
  }

  Future<String> recognizeText(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) {
    return _askMedia(_ocrPrompt, imageBytes, mimeType);
  }

  Future<String> describeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) {
    return _askMedia(_imagePrompt, imageBytes, mimeType);
  }

  Future<String> speechToText(
    Uint8List audioBytes, {
    String mimeType = 'audio/wav',
  }) {
    return _askMedia(_speechPrompt, audioBytes, mimeType);
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<String> _askMedia(
    String instruction,
    Uint8List bytes,
    String mimeType,
  ) async {
    if (bytes.isEmpty) {
      throw const AiInvalidRequestFailure('File tidak berisi data.');
    }

    if (bytes.lengthInBytes > maxInlineBytes) {
      throw const AiFileTooLargeFailure();
    }

    final key = await _requireKey();
    final data = await _post(key, 'generateContent', {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': instruction},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 1024},
    });

    final text = _extractText(data);
    if (text.isEmpty) {
      throw const AiInvalidResponseFailure();
    }

    return text;
  }

  Map<String, dynamic> _textBody(String question, List<AiTurn> history) {
    final contents = <Map<String, dynamic>>[
      ..._normalizeHistory(history),
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    return {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 512},
    };
  }

  List<Map<String, dynamic>> _normalizeHistory(List<AiTurn> history) {
    final normalized = <AiTurn>[];

    for (final turn in history) {
      if (turn.text.trim().isEmpty) {
        continue;
      }

      final role = turn.role == 'model' ? 'model' : 'user';
      if (normalized.isNotEmpty && normalized.last.role == role) {
        continue;
      }

      normalized.add(AiTurn(role: role, text: _privacy.redact(turn.text).text));
    }

    if (normalized.isNotEmpty && normalized.first.role == 'model') {
      normalized.removeAt(0);
    }

    while (normalized.isNotEmpty && normalized.last.role == 'user') {
      normalized.removeLast();
    }

    return normalized
        .map(
          (turn) => {
            'role': turn.role,
            'parts': [
              {'text': turn.text},
            ],
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>> _post(
    String key,
    String method,
    Map<String, dynamic> body,
  ) async {
    http.Response response;

    try {
      response = await _client
          .post(_uri(method), headers: _headers(key), body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw const AiNetworkFailure(
        'Permintaan AI melewati batas waktu. Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException {
      throw const AiNetworkFailure();
    }

    if (response.statusCode != 200) {
      throw _failureForStatus(response.statusCode);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const AiInvalidResponseFailure();
      }

      return decoded;
    } on FormatException {
      throw const AiInvalidResponseFailure();
    }
  }

  Future<String> _requireKey() async {
    final key = await keyStore.readKey();
    if (key == null || key.isEmpty) {
      throw const AiMissingKeyFailure();
    }

    return key;
  }

  Uri _uri(String method, {bool stream = false}) {
    return Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:$method',
      stream ? {'alt': 'sse'} : null,
    );
  }

  Map<String, String> _headers(String key) {
    return {'Content-Type': 'application/json', 'x-goog-api-key': key};
  }

  String _extractText(Map<String, dynamic> data, {bool trim = true}) {
    final candidates = data['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      final feedback = data['promptFeedback'];
      if (feedback is Map && feedback['blockReason'] != null) {
        throw const AiInvalidResponseFailure(
          'Permintaan diblokir oleh penyaring keamanan AI. '
          'Ubah pertanyaan atau gambar lalu coba lagi.',
        );
      }

      return '';
    }

    final first = candidates.first;
    if (first is! Map) {
      return '';
    }

    final content = first['content'];
    if (content is! Map) {
      return '';
    }

    final parts = content['parts'];
    if (parts is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }

    final text = buffer.toString();
    return trim ? text.trim() : text;
  }

  AiFailure _failureForStatus(int status) {
    if (status == 400) {
      return const AiInvalidRequestFailure();
    }

    if (status == 401 || status == 403) {
      return const AiAuthFailure();
    }

    if (status == 404) {
      return const AiInvalidRequestFailure(
        'Model AI tidak ditemukan. Periksa konfigurasi aplikasi.',
      );
    }

    if (status == 429) {
      return const AiRateLimitFailure();
    }

    if (status >= 500) {
      return const AiServerFailure();
    }

    return AiServerFailure(
      'Permintaan AI gagal (kode $status). Coba lagi nanti.',
    );
  }
}
