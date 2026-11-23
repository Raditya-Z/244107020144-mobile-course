class PrivacyResult {
  const PrivacyResult(this.text, this.redactions);

  final String text;
  final int redactions;

  bool get wasRedacted => redactions > 0;
}

class PrivacyGuard {
  const PrivacyGuard();

  static final RegExp _identity = RegExp(
    r'\b(?:NIK|NIP|NIM)\s*[:=]?\s*\d{6,20}\b',
    caseSensitive: false,
  );
  static final RegExp _nik = RegExp(r'\b\d{16}\b');
  static final RegExp _phone = RegExp(r'(?:\+62|62|0)8[0-9]{7,12}\b');
  static final RegExp _email = RegExp(
    r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b',
    caseSensitive: false,
  );
  static final RegExp _address = RegExp(
    r'\b(?:jl\.?|jalan)\s+[^\n,;]{3,60}',
    caseSensitive: false,
  );

  static final List<RegExp> _patterns = [
    _identity,
    _nik,
    _phone,
    _email,
    _address,
  ];

  PrivacyResult redact(String input) {
    var text = input;
    var redactions = 0;

    final steps = <(RegExp, String)>[
      (_identity, '[identitas disamarkan]'),
      (_nik, '[NIK disamarkan]'),
      (_phone, '[nomor telepon disamarkan]'),
      (_email, '[email disamarkan]'),
      (_address, '[alamat disamarkan]'),
    ];

    for (final (pattern, replacement) in steps) {
      text = text.replaceAllMapped(pattern, (match) {
        redactions++;
        return replacement;
      });
    }

    return PrivacyResult(text, redactions);
  }

  bool hasSensitiveData(String input) {
    return _patterns.any((pattern) => pattern.hasMatch(input));
  }
}
