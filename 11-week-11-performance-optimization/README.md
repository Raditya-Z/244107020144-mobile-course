# Minggu 11 — Optimasi Performa (Campus Notify)

Project ini merupakan lanjutan `campus_notify` dari Minggu 10. Fokus minggu ini
bukan menambah fitur, tetapi **mengukur dan mengurangi biaya render** pada dua
layar yang paling sering dipakai: **Catatan** dan **Asisten AI**.

Hasil profiling dan analisis lengkap tersedia di:

- [docs/performance-findings.md](docs/performance-findings.md) — masalah yang
  ditemukan dari profil baseline.
- [docs/performance-report.md](docs/performance-report.md) — metrik
  sebelum/sesudah, flame chart, daftar optimasi, verifikasi, dan refleksi.

## Fitur yang Tetap Berjalan

- **Catatan lokal** (SQLite) dengan pencarian judul, empty state, dan tambah
  catatan.
- **Asisten AI** dengan chat streaming, OCR, Speech-to-Text, Image
  Understanding, serta Pengaturan AI (kunci di secure storage, kuota lokal,
  cache, mode offline).
- Autentikasi simulasi dan pengumuman bawaan project Minggu 7–9.

## Struktur Penting

```text
lib/features/notes/                 # layar Catatan (pencarian, daftar, tambah)
lib/features/ai/presentation/       # Chat, OCR, Suara, Gambar, Pengaturan AI
lib/features/ai/presentation/widgets/image_ai_panel.dart
docs/performance-findings.md        # temuan profiling baseline
docs/performance-report.md          # laporan optimasi + refleksi
screenshots/before-profile.png      # DevTools Performance sebelum
screenshots/after-profile.png       # Frame Analysis sesudah
screenshots/after-timeline.png      # Timeline + CPU samples sesudah
screenshots/memory-profile.png      # Memory page setelah 5x navigasi + GC
test/                               # unit + widget test (49 test)
```

## Cara Menjalankan

```bash
flutter pub get
flutter run -d <device>                 # mode debug untuk pengembangan
flutter run --profile -d <device>       # mode untuk profiling
```

Saat `flutter run --profile`, buka URL DevTools yang tercetak di terminal,
lalu pilih tab **Performance** dan aktifkan perekaman frame. Untuk flame chart
dengan CPU samples, aktifkan **Include CPU samples** sebelum mulai merekam.
Tab **Memory** dipakai untuk heap snapshot dan GC.

Alur aplikasi: login (email mengandung `@`, password ≥ 6 karakter) → beranda →
**Buka Catatan** atau **Asisten AI**. Tanpa kunci API, Asisten AI menampilkan
dialog dan dapat beralih ke **Mode Offline**.

## Optimasi yang Diterapkan

1. `select` pada Riverpod agar AppBar, daftar, banner, input, dan body chat
   hanya rebuild saat datanya berubah.
2. Ekstraksi widget kecil (`_SearchField`, `_NotesList`, `_NoteTile`,
   `_ChatBody`, `_ChatInputBar`, `_KeyBannerGate`) agar scope rebuild sempit.
3. Memoisasi item chat: bubble lama dipakai ulang bila objek pesannya identik.
4. `RepaintBoundary` per bubble dan pada indikator streaming.
5. `ListView.builder` untuk daftar catatan.
6. Lazy tab pada `IndexedStack` Asisten AI (tab dibangun saat pertama dibuka).
7. `cacheWidth` + `RepaintBoundary` untuk pratinjau gambar.
8. Perbaikan kebocoran `TextEditingController` pada sheet Tambah Catatan
   melalui `dispose`.

## Bukti Mesin Hijau

```text
dart format --output=none --set-exit-if-changed lib test
Formatted 57 files (0 changed)

flutter analyze
No issues found! (ran in 5.7s)

flutter test
+49: All tests passed!
```

Test mencakup unit test AI (privasi, kuota, cache, fallback), widget test layar
chat, serta test khusus performa/rebuild:

- `kolom pencarian tidak dibangun ulang saat mengetik`
- `bubble lama tidak dibangun ulang saat pesan baru masuk`

## Hasil Singkat

| Metrik | Sebelum | Sesudah |
|---|---|---|
| FPS rata-rata (scroll cepat) | 57 FPS | 58 FPS |
| Jank terburuk | 27 ms (raster) | tidak ada jank; Raster 15,7 ms |
| Fase UI frame (Frame Analysis) | Build 0,7 / Paint 0,7 ms | Paint 0,6 ms |
| Dart heap setelah 5x buka/tutup + GC | 19,0 MB | 17,8 MB |

Metrik diambil pada perangkat OPPO CPH2473, build profile, dengan skenario yang
sama (detail di [docs/performance-report.md](docs/performance-report.md)).
PSS proses sedikit berbeda antar sesi karena cache engine/DevTools; snapshot
Dart heap tidak menunjukkan pertumbuhan tertahan.

## Screenshots

| Bukti | File |
|---|---|
| Profiling baseline (57 FPS, jank 27 ms) | [before-profile.png](screenshots/before-profile.png) |
| Frame Analysis setelah optimasi (tanpa jank) | [after-profile.png](screenshots/after-profile.png) |
| Timeline + CPU samples setelah optimasi | [after-timeline.png](screenshots/after-timeline.png) |
| Memory setelah 5x navigasi + GC | [memory-profile.png](screenshots/memory-profile.png) |

## Refleksi Singkat

1. **Optimasi paling berdampak:** memisahkan watcher (`select` + widget kecil)
   dan memoisasi bubble + `RepaintBoundary`. Rebuild berantai hilang, jank
   27 ms tidak lagi muncul pada benchmark scroll, dan fase UI < 1 ms.
2. **Bukti bukan plasebo:** skenario, perangkat, dan build sama; dibandingkan
   angka FPS/waktu frame, Frame Analysis, flame chart, serta test yang mengunci
   identitas widget.
3. **Trade-off:** kode lebih terpecah, cache dan `RepaintBoundary` menambah
   sedikit memori/layer, lazy tab menukar waktu buka pertama dengan memori,
   dan `cacheWidth` menurunkan ketajaman gambar di luar ukuran layar.
4. **Hindari optimasi prematur:** ukur dulu lewat profiling; jangan menambah
   `select`/`RepaintBoundary`/cache tanpa bukti bottleneck, terutama untuk
   daftar pendek atau layar yang jarang dibuka.

## Catatan

- Tidak ada kunci API atau secret yang di-commit; kunci diisi pengguna lewat
  Pengaturan AI saat ingin memakai model live.
- Profiling dilakukan di build **profile**, bukan debug, agar mendekati
  performa rilis.
- CPU samples (DevTools) menambah overhead pengukuran; metrik utama diambil
  tanpa CPU samples, sedangkan flame chart memakai CPU samples agar sebanding
  dengan baseline.
