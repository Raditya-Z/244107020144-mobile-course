# Temuan Profiling — Minggu 11

Dokumen ini mencatat temuan pada Langkah 2 (analisis hasil profiling
sebelum optimasi). Bukti mentah ada di
[screenshots/before-profile.png](../screenshots/before-profile.png).

## Lingkungan dan skenario

| Item | Nilai |
|---|---|
| Perangkat | OPPO CPH2473 (Android, 720x1612, density 2.0/2.125) |
| Mode | `flutter run --profile` (AOT, bukan debug) |
| Flutter / Dart | 3.47.6 stable / Dart 3.13.5 |
| DevTools | Performance page, Flutter frame recording aktif |

Skenario yang direkam sama untuk sebelum dan sesudah:

1. Buka **Catatan** (12 catatan).
2. Scroll cepat ke atas-bawah 3 kali.
3. Ketik `Performa` pada kolom cari, lalu hapus.
4. Kembali ke beranda.
5. Buka **Asisten AI**, pilih chip saran, tampilkan dialog kunci API,
   pilih **Mode Offline**.
6. Kirim pesan singkat, tutup dialog, kembali ke beranda.

## Ringkasan baseline

- **57 FPS rata-rata**, dengan frame **Raster Jank hingga 27 ms** pada jendela
  chart yang terekam (batas 60 FPS = 16,7 ms).
- Fase UI frame yang diperiksa: **Build 0,7 ms**, **Paint 0,7 ms**; lonjakan
  ada di fase raster dan pada frame-frame yang membangun ulang subtree besar.
- PSS proses sekitar **190 MB** (`dumpsys meminfo`: TOTAL PSS 195.068 KB).

Angka di atas menjadi pembanding pada
[docs/performance-report.md](performance-report.md).

## Masalah yang ditemukan

### 1. Seluruh halaman Catatan dibangun ulang setiap ketikan

- **Gejala:** mengetik di kolom cari memicu aktivitas frame yang tidak perlu;
  daftar, AppBar, dan kolom pencarian ikut dijalankan ulang untuk setiap huruf.
- **Penyebab:** `NotesPage` menonton `searchQueryProvider` secara utuh, sehingga
  perubahan kueri (setiap huruf) merebuild semua widget di halaman — termasuk
  `TextField` yang sedang dipakai mengetik.
- **Perbaikan:** AppBar hanya menonton
  `select((query) => query.trim().isNotEmpty)`; kolom cari dipisah menjadi
  `_SearchField` yang tidak menonton apa pun; daftar dipisah menjadi
  `_NotesList` yang membaca kueri + daftar catatan dan memakai
  `ListView.builder`.
- **Verifikasi:** widget test baru memastikan instance `TextField` tetap sama
  saat ketikan kedua dan seterusnya.

### 2. Root `ChatScreen` ikut rebuild pada setiap chunk streaming

- **Gejala:** saat jawaban AI bertambah per chunk, frame UI lebih berat dan
  seluruh layar (banner kunci, daftar bubble, input) ikut dibangun ulang.
- **Penyebab:** satu `ref.watch(chatControllerProvider)` di root layar.
- **Perbaikan:** root hanya memakai `ref.listen` (untuk auto-scroll dan dialog
  error). Bagian-bagian memakai `select` sendiri:
  `_KeyBannerGate` (status kunci), `_ChatBody` (`messages` dan `isStreaming`),
  `_ChatInputBar` (`isStreaming` dan pemakaian kuota).
- **Verifikasi:** bubble lama tetap berupa instance widget yang sama ketika
  pesan baru masuk (widget test).

### 3. Bubble lama dibangun ulang dan ikut repaint

- **Gejala:** setiap pesan baru/chunk membuat semua bubble dibangun ulang;
  tidak ada batas repaint antarbubble.
- **Penyebab:** daftar pesan dibangun ulang dari nol dan tidak dibungkus
  `RepaintBoundary`.
- **Perbaikan:** `_ChatBody` menyimpan cache `_items` dan hanya membangun ulang
  bubble yang objek pesannya berubah (perbandingan `identical`), serta
  membungkus tiap bubble dengan `RepaintBoundary(key: ValueKey(i))`; indikator
  streaming juga dibungkus `RepaintBoundary`.
- **Verifikasi:** widget test "bubble lama tidak dibangun ulang saat pesan baru
  masuk" lulus; frame raster saat streaming lebih ringan.

### 4. Semua tab Asisten AI dibangun sejak awal

- **Gejala:** membuka Chat juga membangun tab OCR, Suara, dan Gambar beserta
  widget kamera/audio/gambar yang belum dipakai.
- **Penyebab:** `IndexedStack` dengan seluruh halaman sebagai children.
- **Perbaikan:** `IndexedStack` tetap dipakai agar state tab terjaga, tetapi
  halaman baru dibuat saat pertama kali dikunjungi (`_visited`), sisanya
  `SizedBox.shrink()`.
- **Verifikasi:** membuka tab lain untuk pertama kali baru memicu inisialisasi;
  tidak ada listener kamera/mikrofon saat aplikasi idle di tab Chat.

### 5. Pratinjau gambar didekode pada resolusi penuh

- **Gejala:** memilih foto besar untuk OCR/Image Understanding menaikkan memori
  dan waktu raster karena `Image.memory` mendekode seluruh piksel.
- **Penyebab:** tidak ada `cacheWidth`; ukuran dekode mengikuti file asli.
- **Perbaikan:** `cacheWidth = lebar layar * devicePixelRatio` dan pembungkusan
  `RepaintBoundary`, sehingga bitmap yang disimpan sesuai kebutuhan layar.
- **Verifikasi:** gambar kamera 12 MP didekode ke ~720–1080 px; tidak ada
  lonjakan memori saat pratinjau muncul.

### 6. Controller sheet "Tambah Catatan" tidak pernah di-dispose

- **Gejala:** setiap kali sheet dibuka, sebuah `TextEditingController` dibuat
  dan ditinggalkan tanpa `dispose` setelah sheet ditutup.
- **Penyebab:** controller dibuat di fungsi `showAddNoteSheet` dan tidak
  memiliki pemilik yang jelas.
- **Perbaikan:** sheet dipindah menjadi `_AddNoteSheet` (StatefulWidget) yang
  membuat controller di `initState` dan melepasnya di `dispose`.
- **Verifikasi:** 5 kali buka/tutup sheet + GC: Dart heap **19,0 MB → 17,8 MB**
  (tidak ada pertumbuhan tertahan) — lihat Langkah 5 di laporan.

## Prioritas perbaikan

| Prioritas | Masalah | Alasan |
|---|---|---|
| 1 | #2 dan #3 (chat/streaming) | Paling sering memicu rebuild berantai pada skenario AI |
| 2 | #1 (pencarian Catatan) | Setiap ketikan merebuild halaman penuh |
| 3 | #4 (tab AI) | Biaya inisialisasi besar saat pertama membuka Asisten AI |
| 4 | #5 (dekode gambar) | Memori/raster pada gambar besar |
| 5 | #6 (leak controller) | Kecil per kejadian, tetapi menumpuk bila berulang |
