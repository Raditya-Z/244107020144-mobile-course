# AI Log — Minggu 10: Integrasi Fitur AI

Log ini mencatat integrasi fitur AI pada project `campus_notify` hasil Minggu 9,
meliputi chat, OCR, Speech-to-Text, dan Image Understanding. Semua permintaan
dikirim ke Gemini API (`gemini-3.5-flash-lite`) melalui package `http`, dengan kunci
API disimpan di `flutter_secure_storage` dan dikirim lewat header
`x-goog-api-key` (bukan di URL).

Alur kerja: **Prompt → Integrasi → Verifikasi → Test → Dokumentasi**.

## 1. Konteks Project

Fitur baru ditempatkan pada `lib/features/ai/` mengikuti pola feature-first
Clean Architecture yang sudah dipakai Minggu 7 dan 9.

```text
lib/ai/                                  # lapisan layanan AI lintas fitur
  ai_service.dart                        # Gemini client: teks, SSE, OCR, STT, gambar
  ai_failures.dart                       # sealed failure yang ramah pengguna
  privacy_guard.dart                     # penyamaran data pribadi sebelum dikirim
  ai_usage_limiter.dart                  # kuota lokal 20 permintaan/hari
  ai_cache.dart                          # cache jawaban lokal (20 entri, 7 hari)
  ai_fallback.dart                       # jawaban lokal saat layanan AI gagal
  ai_key_store.dart / ai_storage.dart    # kunci API + penyimpanan aman
lib/features/ai/presentation/
  pages/chat_screen.dart                 # chat streaming
  pages/ocr_screen.dart                  # OCR
  pages/speech_screen.dart               # Speech-to-Text
  pages/image_screen.dart                # Image Understanding
  pages/ai_settings_screen.dart          # pengaturan kunci, kuota, privasi, model
  pages/ai_assistant_page.dart           # navigasi Chat/OCR/Suara/Gambar
  providers/ai_providers.dart            # DI Riverpod + state chat
  widgets/                               # panel gambar, dialog, kartu hasil
```

Catatan: modul mencontohkan `lib/features/chat_screen.dart`. Pada project ini
halaman ditempatkan di `lib/features/ai/presentation/pages/chat_screen.dart`
agar konsisten dengan struktur feature-first yang sudah ada; isi dan perilaku
tetap sesuai modul.

Dependensi baru: `http`, `image_picker`, `record`, `path_provider`. Kunci API
tidak pernah ditulis di source code dan tidak ikut di-commit.

## 2. Prompt Sistem

Prompt sistem dikirim pada setiap permintaan chat melalui `system_instruction`.
Isinya diambil langsung dari `AiService.systemPrompt`:

```text
Kamu adalah asisten kampus Campus Notify. Jawab dalam Bahasa Indonesia yang
ramah dan singkat, maksimal 2 kalimat. Jangan meminta atau mengulang data
pribadi seperti NIK, nomor telepon, alamat, atau email. Jika informasi tidak
tersedia, katakan dengan jujur dan sarankan menghubungi admin kampus.
```

Alasan pemilihan:

- Membatasi peran agar jawaban tetap relevan dengan konteks kampus.
- Membatasi panjang jawaban supaya cocok untuk layar mobile dan hemat token.
- Melarang model meminta/mengulang data pribadi sebagai lapisan kedua setelah
  `PrivacyGuard`.
- Memberi instruksi jujur saat informasi tidak tersedia agar aplikasi tidak
  menampilkan jawaban yang mengarang.

## 3. User Prompt per Fitur

### 3.1 Chat

Pesan pengguna dikirim setelah disamarkan oleh `PrivacyGuard`. Riwayat
percakapan (maksimal 6 giliran terakhir) ikut dikirim agar konteks percakapan
terjaga. Contoh pertanyaan yang diuji pada perangkat:

```text
Apa itu Campus Notify?
```

```text
HP saya 081234567890, tolong jawab apa itu Campus Notify?
```

Pada contoh kedua, nomor telepon diganti `[nomor telepon disamarkan]` sebelum
dikirim, dan aplikasi menampilkan label "1 data pribadi disamarkan sebelum
dikirim" pada gelembung pesan.

Bentuk body yang dikirim ke `models/gemini-3.5-flash-lite:streamGenerateContent?alt=sse`:

```json
{
  "system_instruction": {
    "parts": [{ "text": "<systemPrompt di atas>" }]
  },
  "contents": [
    { "role": "user", "parts": [{ "text": "<pertanyaan yang sudah disamarkan>" }] }
  ],
  "generationConfig": { "temperature": 0.4, "maxOutputTokens": 512 }
}
```

### 3.2 OCR

Instruksi yang dikirim bersama gambar (`inline_data`, base64, maksimal 6 MB):

```text
Ekstrak seluruh teks yang terlihat pada gambar. Pertahankan urutan baris.
Jika tidak ada teks, jawab "Tidak ada teks yang terdeteksi." Jangan
menambahkan penjelasan lain.
```

### 3.3 Image Understanding

```text
Jelaskan isi gambar ini secara singkat dalam Bahasa Indonesia, maksimal
3 kalimat. Sebutkan objek utama dan konteks yang terlihat.
```

### 3.4 Speech-to-Text

Rekaman dibuat dalam format WAV 16 kHz mono, maksimal 60 detik, lalu dikirim
sebagai `inline_data` dengan instruksi:

```text
Transkripsikan seluruh ucapan pada audio ini ke dalam Bahasa Indonesia.
Tulis hanya transkrip, tanpa penjelasan tambahan.
```

Parameter untuk permintaan media: `temperature: 0.2`, `maxOutputTokens: 1024`.

## 4. Output Awal AI

Pengujian dilakukan pada HP fisik (CPH2473) dengan kunci Gemini yang diisi
melalui **Pengaturan AI**. Pertanyaan yang dikirim:

```text
Apa itu Campus Notify?
```

Jawaban model `gemini-3.5-flash-lite` yang tampil pertama kali (verbatim,
`screenshots/13-chat-ai-live.png`):

```text
Halo! Campus Notify adalah asisten virtual kampus yang siap membantu
memberikan informasi seputar kegiatan dan layanan akademik dengan cepat.
Jika butuh info lebih lanjut, silakan tanyakan atau hubungi admin kampus ya!
```

Gelembung diberi label **Asisten AI** tanpa penanda cache/offline, sehingga
jawaban berasal langsung dari model.

Uji multimodal juga berhasil:

- **Image Understanding** (`screenshots/14-gambar-hasil.png`) — dari gambar
  tangkapan pesan pembatalan kuliah, model menghasilkan: "Gambar ini
  menunjukkan sebuah tangkapan layar pesan teks dari aplikasi perpesanan.
  Objek utamanya adalah pesan yang berisi pemberitahuan pembatalan kuliah.
  Konteksnya adalah pengumuman dari seseorang bernama Ici kepada Felis bahwa
  kelas Pengantar Bisnis dan Manajemen ditiadakan dan dijadwalkan ulang
  minggu depan."
- **OCR** (`screenshots/15-ocr-hasil.png`) — teks pada gambar statistik waktu
  layar berhasil diekstrak (05.30, 2,00 KB/s, 29%, 23/11, 22/11, "Urutan dari
  baru ke lama...", "Statistik Waktu Layar").

### Catatan troubleshooting model

Percobaan pertama gagal dengan HTTP 404 "Model AI tidak ditemukan" karena
`gemini-2.5-flash` sudah deprecated dan akses API-nya dibatasi untuk pengguna
lama. Alias `gemini-flash-latest` masih menghasilkan HTTP 500 pada pengujian,
sehingga model default diganti ke `gemini-3.5-flash-lite` (model stabil yang
direkomendasikan dokumentasi Gemini untuk project baru). Setelah perubahan ini
chat dan Image Understanding berhasil. OCR sempat melewati batas waktu 30 detik
sekali, lalu berhasil saat tombol **Coba Lagi** ditekan.

Perilaku tanpa kunci API tetap dipertahankan sebagai bukti fallback: dialog
"Kunci API Belum Diatur" (`screenshots/04-dialog-kunci-api.png`) dan jawaban
**Mode Offline** (`screenshots/05-chat-mode-offline.png`) dari `AiFallback`:

```text
Campus Notify membantu membaca pengumuman, menyimpan catatan lokal, dan
memakai fitur AI saat koneksi tersedia.
```

## 5. Verifikasi dan Keputusan

| Aspek | Keputusan |
|---|---|
| Kunci API | Disimpan di `flutter_secure_storage`, dikirim lewat header `x-goog-api-key` |
| Privasi | Teks disamarkan di `PrivacyGuard` sebelum dikirim; gambar/audio hanya dikirim saat tombol analisis ditekan |
| Streaming | Respons SSE (`alt=sse`) dibaca per baris `data:` dan hanya bagian `text` yang ditampilkan |
| Kuota | Maksimal 20 permintaan/hari dihitung lokal; ditolak dengan `AiQuotaFailure` |
| Cache | Jawaban disimpan lokal (20 entri, 7 hari) dengan kunci yang dinormalisasi; pertanyaan sama tidak memanggil API ulang |
| Error | Status 400/401/403/404/429/5xx, timeout, dan gangguan jaringan dipetakan ke failure dengan pesan ramah dan opsi coba lagi/mode offline |
| Keamanan respons | `promptFeedback.blockReason` dan kandidat kosong ditangani sebagai `AiInvalidResponseFailure` |
| Ukuran berkas | Gambar/audio di atas 6 MB ditolak sebelum dikirim |
| Model | `gemini-3.5-flash-lite`; model 2.5 sudah deprecated sehingga tidak dipakai |
| Pengujian | 47 test lulus; mencakup privacy guard, kuota, cache, fallback, service (mock HTTP + SSE), dan widget chat |

Catatan biaya: kuota lokal membatasi jumlah panggilan per hari, cache
mengurangi panggilan berulang, dan jawaban dibatasi 512 token untuk chat serta
1024 token untuk media. Batas dan tarif resmi dari provider tetap berlaku.
