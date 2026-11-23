import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_notify/ai/ai_failures.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/ai_fakes.dart';

http.Response _chatResponse(String text) {
  return http.Response(
    jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    }),
    200,
  );
}

class _SseClient extends http.BaseClient {
  _SseClient(this.payloads);

  final List<Map<String, dynamic>> payloads;
  late http.BaseRequest lastRequest;
  late String lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (request is http.Request) {
      lastBody = request.body;
    }

    final body = payloads
        .map((payload) => 'data: ${jsonEncode(payload)}\n\n')
        .join();

    return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
  }
}

void main() {
  test(
    'mengirim system prompt, kunci di header, dan data tersamarkan',
    () async {
      late http.Request captured;
      final service = AiService(
        keyStore: FakeAiKeyStore('test-key'),
        client: MockClient((request) async {
          captured = request;
          return _chatResponse('Halo juga');
        }),
      );

      final answer = await service.ask(
        'HP saya 081234567890',
        history: const [
          AiTurn(role: 'user', text: 'Email saya budi@example.com'),
          AiTurn(role: 'model', text: 'Baik'),
        ],
      );

      expect(answer, 'Halo juga');
      expect(captured.method, 'POST');
      expect(
        captured.url.path,
        '/v1beta/models/gemini-3.5-flash-lite:generateContent',
      );
      expect(captured.headers['x-goog-api-key'], 'test-key');
      expect(captured.url.query, isNot(contains('test-key')));

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final system = body['system_instruction'] as Map<String, dynamic>;
      final systemParts = system['parts'] as List;
      expect(
        (systemParts.first as Map<String, dynamic>)['text'],
        AiService.systemPrompt,
      );

      expect(captured.body, isNot(contains('081234567890')));
      expect(captured.body, isNot(contains('budi@example.com')));
      expect(captured.body, contains('[nomor telepon disamarkan]'));
      expect(captured.body, contains('[email disamarkan]'));
    },
  );

  test('tanpa kunci API tidak memanggil jaringan', () async {
    var called = false;
    final service = AiService(
      keyStore: FakeAiKeyStore(),
      client: MockClient((request) async {
        called = true;
        return _chatResponse('Tidak dipakai');
      }),
    );

    await expectLater(service.ask('Halo'), throwsA(isA<AiMissingKeyFailure>()));
    expect(called, isFalse);
  });

  test('status HTTP dipetakan ke failure yang ramah', () async {
    Future<AiFailure> failureFor(int status) async {
      final service = AiService(
        keyStore: FakeAiKeyStore('test-key'),
        client: MockClient((request) async => http.Response('{}', status)),
      );

      try {
        await service.ask('Halo');
        fail('Permintaan seharusnya gagal');
      } on AiFailure catch (failure) {
        return failure;
      }
    }

    expect(await failureFor(400), isA<AiInvalidRequestFailure>());
    expect(await failureFor(403), isA<AiAuthFailure>());
    expect(await failureFor(429), isA<AiRateLimitFailure>());
    expect(await failureFor(500), isA<AiServerFailure>());
  });

  test('respons tanpa kandidat dianggap tidak valid', () async {
    final service = AiService(
      keyStore: FakeAiKeyStore('test-key'),
      client: MockClient((request) async {
        return http.Response(jsonEncode({'candidates': []}), 200);
      }),
    );

    await expectLater(
      service.ask('Halo'),
      throwsA(isA<AiInvalidResponseFailure>()),
    );
  });

  test('blokir keamanan AI menghasilkan pesan yang jelas', () async {
    final service = AiService(
      keyStore: FakeAiKeyStore('test-key'),
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'promptFeedback': {'blockReason': 'SAFETY'},
          }),
          200,
        );
      }),
    );

    await expectLater(
      service.ask('Pertanyaan sensitif'),
      throwsA(
        isA<AiInvalidResponseFailure>().having(
          (failure) => failure.message,
          'message',
          contains('penyaring keamanan'),
        ),
      ),
    );
  });

  test('OCR mengirim inline data dan prompt ekstraksi', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    late http.Request captured;

    final service = AiService(
      keyStore: FakeAiKeyStore('test-key'),
      client: MockClient((request) async {
        captured = request;
        return _chatResponse('Teks dari gambar');
      }),
    );

    final text = await service.recognizeText(bytes, mimeType: 'image/png');

    expect(text, 'Teks dari gambar');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    final contents = body['contents'] as List;
    final parts = (contents.first as Map<String, dynamic>)['parts'] as List;
    final inline =
        (parts[1] as Map<String, dynamic>)['inline_data']
            as Map<String, dynamic>;

    expect(inline['mime_type'], 'image/png');
    expect(inline['data'], base64Encode(bytes));
    expect(
      ((parts.first as Map<String, dynamic>)['text'] as String),
      contains('Ekstrak seluruh teks'),
    );
  });

  test('streaming menggabungkan potongan jawaban', () async {
    final client = _SseClient([
      {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Halo'},
              ],
            },
          },
        ],
      },
      {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': ' dunia'},
              ],
            },
          },
        ],
      },
    ]);

    final service = AiService(
      keyStore: FakeAiKeyStore('test-key'),
      client: client,
    );

    final chunks = await service.askStream('Halo').toList();

    expect(chunks.join(), 'Halo dunia');
    expect(client.lastRequest.url.queryParameters['alt'], 'sse');
    expect(client.lastRequest.headers['x-goog-api-key'], 'test-key');
    expect(client.lastBody, contains('system_instruction'));
  });
}
