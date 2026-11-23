# Minggu 10 — Integrasi Fitur AI (Campus Notify)

Project ini merupakan lanjutan `campus_notify` dari Minggu 9. Pada minggu ini
ditambahkan **Asisten AI** yang memakai Gemini API (`gemini-3.5-flash-lite`) untuk
chat streaming, OCR, Speech-to-Text, dan Image Understanding, lengkap dengan
perlindungan privasi, kuota lokal, cache, serta fallback saat layanan AI gagal.

## Fitur yang Diintegrasikan

- **Chat dengan streaming** — pertanyaan dikirim ke Gemini dan jawaban muncul
  bertahap (SSE). Pengguna dapat menghentikan jawaban yang sedang berjalan.
- **OCR** — ambil gambar dari galeri/kamera, lalu ekstrak teksnya.
- **Speech-to-Text** — rekam suara (maksimal 60 detik) dan transkripsikan.
- **Image Understanding** — minta deskripsi singkat dari gambar.
- **Pengaturan AI** — simpan/hapus kunci API, lihat kuota harian, daftar
  praktik privasi, dan informasi model.
- **Privasi** — NIK/NIP/NIM, NIK 16 digit, nomor telepon, email, dan alamat
  disamarkan sebelum teks dikirim; gambar/audio hanya dikirim saat tombol
  analisis ditekan.
- **Biaya dan keandalan** — kuota 20 permintaan/hari, cache jawaban lokal
  7 hari, mode offline, tombol coba lagi, dan pesan error yang ramah.

File utama:

```text
lib/ai/                                  # layanan AI, privasi, kuota, cache, fallback
lib/features/ai/presentation/            # Chat, OCR, Suara, Gambar, Pengaturan AI
lib/features/ai/presentation/providers/  # DI Riverpod + state chat
lib/routes.dart, lib/router.dart         # rute /ai dan /ai/pengaturan
test/                                    # unit test + widget test fitur AI
docs/ai-log.md                           # prompt sistem, user prompt, output awal
screenshots/                             # tangkapan layar perangkat
```

Modul mencontohkan `lib/features/chat_screen.dart`; pada project ini halaman
ditempatkan di `lib/features/ai/presentation/pages/chat_screen.dart` agar
konsisten dengan struktur feature-first yang sudah dipakai sejak Minggu 7/9.

## Cara Menjalankan

```bash
flutter pub get
flutter run -d <device>
```

1. Login memakai autentikasi simulasi yang sudah ada: email apa pun yang
   mengandung `@` dan password minimal 6 karakter.
2. Dari halaman utama, buka **Asisten AI**.
3. Buka ikon **Pengaturan AI**, tempel kunci Gemini dari
   <https://aistudio.google.com/app/apikey>, lalu simpan.
4. Tanpa kunci API, fitur AI menampilkan dialog dan dapat beralih ke
   **Mode Offline**.

Izin yang disiapkan: `RECORD_AUDIO` (Android) serta kamera, mikrofon, dan
galeri (iOS melalui `Info.plist`). Galeri Android memakai Photo Picker sehingga
tidak meminta izin penyimpanan penuh.

## Bukti Mesin Hijau

```text
flutter analyze
No issues found! (ran in 5.7s)

flutter test
+47: All tests passed!
```

Test mencakup `PrivacyGuard`, kuota harian, cache, fallback lokal, `AiService`
(mock HTTP + SSE), serta widget test layar chat (dialog kunci, penyamaran data,
streaming, dan cache).

## Tabel Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Bocor data pengguna | `PrivacyGuard` menyamarkan NIK/NIP/NIM, NIK 16 digit, nomor telepon, email, dan alamat sebelum teks dikirim; prompt sistem melarang meminta/mengulang data pribadi; gambar/audio hanya dikirim saat tombol analisis ditekan |
| Kunci API bocor | Kunci disimpan di `flutter_secure_storage`, ditampilkan tersamarkan, dikirim lewat header `x-goog-api-key` (bukan URL), dan tidak ditulis ke log atau source code |
| Biaya melonjak | Kuota lokal 20 permintaan/hari, cache 20 entri selama 7 hari, jawaban dibatasi 512 token (chat) dan 1024 token (media), serta pengiriman hanya atas aksi pengguna |
| API error/down | Pesan error ramah per jenis kegagalan, tombol coba lagi, stop streaming, cache lokal, dan mode offline dengan `AiFallback` |
| Respons tidak relevan/tidak akurat | Prompt sistem ringkas dan berkonteks kampus, temperature rendah, respons kosong/terblokir ditangani, disclaimer "AI dapat salah. Periksa informasi penting.", dan fallback ke data lokal |
| Berkas terlalu besar | Gambar/audio di atas 6 MB ditolak sebelum dikirim dengan pesan yang jelas |
| Data pribadi pada gambar/audio | Peringatan eksplisit di layar OCR/Suara/Gambar untuk tidak mengunggah dokumen berisi NIK atau data sensitif |

## Screenshots

| Tampilan | File |
|---|---|
| Login | [01-login.png](screenshots/01-login.png) |
| Halaman utama + Asisten AI | [02-home-asisten-ai.png](screenshots/02-home-asisten-ai.png) |
| Chat kosong + banner kunci | [03-chat-kosong.png](screenshots/03-chat-kosong.png) |
| Dialog kunci API belum diatur | [04-dialog-kunci-api.png](screenshots/04-dialog-kunci-api.png) |
| Jawaban mode offline | [05-chat-mode-offline.png](screenshots/05-chat-mode-offline.png) |
| Data pribadi disamarkan | [06-privasi-disamarkan.png](screenshots/06-privasi-disamarkan.png) |
| Tab OCR | [07-ocr.png](screenshots/07-ocr.png) |
| Gambar dipilih untuk OCR | [08-ocr-gambar-dipilih.png](screenshots/08-ocr-gambar-dipilih.png) |
| Error kunci saat OCR | [09-ocr-error-kunci.png](screenshots/09-ocr-error-kunci.png) |
| Tab Suara | [10-suara.png](screenshots/10-suara.png) |
| Tab Gambar | [11-gambar.png](screenshots/11-gambar.png) |
| Pengaturan AI (kuota, privasi, model) | [12-pengaturan-ai.png](screenshots/12-pengaturan-ai.png) |
| Jawaban AI live (Gemini) | [13-chat-ai-live.png](screenshots/13-chat-ai-live.png) |
| Hasil Image Understanding | [14-gambar-hasil.png](screenshots/14-gambar-hasil.png) |
| Hasil OCR | [15-ocr-hasil.png](screenshots/15-ocr-hasil.png) |
| Hasil Transkripsi Suara | [16-suara-hasil.png](screenshots/16-suara-hasil.png) |

## Refleksi

**1. Fitur AI mana yang diintegrasikan dan mengapa?**
Saya mengintegrasikan empat fitur: chat streaming, OCR, Speech-to-Text, dan
Image Understanding. Chat menjadi fitur utama karena paling sering dipakai
untuk bertanya tentang informasi kampus. OCR dan Image Understanding membantu
membaca papan pengumuman, KTM, atau struk, sedangkan Speech-to-Text memberi
jalur input cepat dan lebih aksesibel. Semua fitur memakai satu layanan
`AiService` agar penanganan privasi, kuota, dan error konsisten.

**2. Bagaimana melindungi privasi pengguna saat menggunakan AI API?**
Sebelum teks dikirim, `PrivacyGuard` menyamarkan NIK/NIP/NIM, NIK 16 digit,
nomor telepon, email, dan alamat. Prompt sistem juga melarang model meminta
atau mengulang data pribadi. Gambar dan audio tidak dikirim otomatis; pengguna
harus menekan tombol analisis, dan layar memberi peringatan agar tidak
mengunggah dokumen sensitif. Kunci API disimpan di secure storage, dikirim
lewat header (bukan URL), dan isi percakapan tidak ditulis ke log.

**3. Fallback apa yang disediakan jika layanan AI error?**
Setiap kegagalan dipetakan ke pesan yang ramah (kunci belum diatur, kuota
habis, kunci ditolak, rate limit, jaringan, server). Pengguna mendapat tombol
coba lagi, dapat menghentikan streaming, dan dapat memilih mode offline.
Mode offline memakai cache jawaban lokal (7 hari) atau `AiFallback` berisi
jawaban lokal untuk topik umum kampus. Jika tidak ada keduanya, aplikasi
menampilkan saran menghubungi admin kampus.

**4. Satu hal yang dipelajari tentang UX fitur AI di mobile?**
Latensi adalah bagian dari UX. Menunggu jawaban tanpa umpan balik membuat
aplikasi terasa macet, sehingga streaming, indikator "Menulis jawaban...",
tombol stop, dan label sumber jawaban (AI, cache, offline) menjadi penting.
Selain itu, pengguna perlu tahu kapan data mereka dikirim: dialog izin,
label "data pribadi disamarkan", dan disclaimer akurasi membuat fitur AI
terasa transparan dan dapat dikendalikan.

## Dokumentasi Prompt

Prompt sistem, prompt per fitur, bentuk request, serta output awal yang
terekam tersedia di [docs/ai-log.md](docs/ai-log.md).

## Catatan

- Tidak ada kunci API atau secret yang di-commit; kunci diisi pengguna lewat
  Pengaturan AI.
- Autentikasi masih simulasi bawaan project Minggu 7/9 dan tidak diubah.
- Pengujian perangkat memakai HP fisik; respons model live memerlukan kunci
  Gemini yang valid di perangkat.
- Model yang dipakai `gemini-3.5-flash-lite`. Model `gemini-2.5-flash` sudah
  deprecated (respons 404) sehingga diganti ke model stabil yang
  direkomendasikan untuk project baru.
