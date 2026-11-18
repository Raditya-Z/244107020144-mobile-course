# AI Log — Minggu 9: AI-Assisted Development / Vibe Coding

Log ini mencatat pemakaian AI pada pengerjaan fitur **Search Notes** (pencarian judul catatan dengan empty state) pada project `campus_notify` hasil refactor Minggu 7. Workflow yang diikuti: **Prompt → Generate → Verify → Test → Refactor → Explain**. AI dipakai sebagai generator dan reviewer awal; setiap keputusan verifikasi, perbaikan, dan penerimaan ditinjau dan disetujui oleh penulis.

## 1. Konteks Project yang Ditempel ke AI

Struktur folder `campus_notify` (feature-first, Clean Architecture):

```text
lib/features/notes/
  presentation/
    pages/notes_page.dart        # ConsumerWidget, pakai notesProvider + state.when
    providers/notes_providers.dart
  domain/
    entities/note.dart           # Note { id, title, body, updatedAt, dirty }
    repositories/note_repository.dart
    usecases/get_notes.dart      # GetNotes.call() -> ({List<Note> notes, Failure? failure})
  data/
    models/note_model.dart
    repositories/note_repository_impl.dart   # sqflite, query('notes', orderBy: updated_at DESC)
    services/notes_database.dart
```

Kontrak repository yang sudah ada (tidak boleh diubah):

```dart
abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();
  Future<({Note? note, Failure? failure})> addNote({required String title, String body = ''});
}
```

Versi package dari `pubspec.yaml`:

```text
flutter_riverpod: ^3.4.3
go_router: ^18.0.2
dio: ^5.11.1
sqflite: ^2.4.5
flutter_lints: ^6.0.0 (dev)
sdk: ^3.13.1
```

Yang **tidak boleh diubah**: arsitektur `presentation -> domain <- data`, kontrak `NoteRepository`/`GetNotes`, halaman lain, dan dependensi baru.

## 2. Prompt Mentah (Formula 5 Slot)

```text
Peran: senior Flutter dev
Konteks: project campus_notify, feature-first (presentation->domain<-data),
  Riverpod 3 (flutter_riverpod ^3.4.3), SQLite via sqflite ^2.4.5 + Dio.
  NotesPage saat ini ConsumerWidget yang watch notesProvider (FutureProvider<List<Note>>),
  daftar note di-load lewat use case GetNotes -> NoteRepository.fetchNotes().
Tugas: tambah pencarian judul notes di NotesPage: search bar di AppBar,
  hasil terfilter saat diketik, empty state "Tidak ada catatan yang cocok"
  ketika query tidak menemukan apa pun. Pencarian tidak case-sensitive.
Batas: jangan ubah arsitektur dan jangan tambah package; jangan ubah kontrak
  NoteRepository/GetNotes; jangan panggil SQLite dari widget; maks 80 baris per file.
Output: kode implementasi + 3 test case (query cocok, query tak cocok,
  case-insensitive) + 1 widget test empty state + cara jalankan analyze dan test.
```

Prompt di atas mengikuti formula 5 slot jobsheet (Peran, Konteks, Tugas, Batas, Output) dan contoh prompt "baik" pada bagian Prompt Engineering. Tidak ada secret/token yang ditempel; konteks yang diberikan hanya potongan kode kontrak dan versi package.

## 3. Output Awal AI

Draf pertama yang dihasilkan AI (sebelum verifikasi; whitespace sudah dinormalisasi `dart format`, tetapi struktur dan isi tidak diubah). Tiga file.

### 3.1 `lib/features/notes/presentation/pages/notes_page.dart` (draf)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/note.dart';
import '../providers/notes_providers.dart';

/// Saring catatan berdasarkan judul; pencarian tidak peka huruf besar/kecil.
List<Note> filterNotes(List<Note> notes, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return notes;
  }

  return notes
      .where((note) => note.title.toLowerCase().contains(normalized))
      .toList();
}

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _query.isEmpty ? const Text('Catatan') : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Cari judul catatan',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (notes) {
          final filtered = filterNotes(notes, _query);

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                _query.trim().isEmpty
                    ? 'Tidak ada catatan yang cocok.'
                    : 'Tidak ada catatan yang cocok.',
              ),
            );
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final note = filtered[index];

              return ListTile(
                title: Text(note.title),
                subtitle: note.body.isEmpty ? null : Text(note.body),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 3.2 `test/search_filter_test.dart` (draf)

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';

void main() {
  final list = [
    Note(title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1)),
    Note(title: 'Rencana belanja buku', updatedAt: DateTime(2026, 11, 2)),
    Note(title: 'Tugas pemrograman', updatedAt: DateTime(2026, 11, 3)),
  ];

  test('query cocok mengembalikan catatan yang sesuai', () {
    expect(filterNotes(list, 'belanja'), hasLength(2));
  });

  test('query tak cocok mengembalikan kosong', () {
    expect(filterNotes(list, 'zzz-tak-ada'), isEmpty);
  });

  test('pencarian mengabaikan besar kecil huruf', () {
    expect(filterNotes(list, 'BELANJA'), hasLength(2));
    expect(filterNotes(list, 'Belanja'), hasLength(2));
  });
}
```

### 3.3 `test/notes_page_search_test.dart` (draf, ringkasan)

File ini mendefinisikan `FakeNoteRepository` (implementasi `NoteRepository` yang mengembalikan daftar tetap), meng-override `noteRepositoryProvider` di dalam `ProviderScope`, lalu dua `testWidgets`: (1) mengetik `zzz-tak-ada` dan mengharapkan teks `Tidak ada catatan yang cocok.` tanpa `ListView`; (2) mengetik `BELANJA` dan mengharapkan hanya `Belanja bulanan` yang tampil.

Catatan: draf ini adalah **output AI awal apa adanya**, sebelum dibaca manusia. Kesalahannya dibiarkan utuh supaya terbukti pada tahap verifikasi.

## 4. Verifikasi 6 Langkah

Kode draf dijalankan apa adanya pada mesin (setelah `dart format`):

```text
$ flutter analyze
error - The name 'Note' isn't a type, so it can't be used as a type argument.
  - lib\features\notes\presentation\pages\notes_page.dart:8:6 - non_type_as_type_argument
error - The name 'Note' isn't a type, so it can't be used as a type argument.
  - lib\features\notes\presentation\pages\notes_page.dart:8:29 - non_type_as_type_argument
error - The property 'title' can't be unconditionally accessed because the receiver can be 'null'.
  - lib\features\notes\presentation\pages\notes_page.dart:15:29 - unchecked_use_of_nullable_value
4 issues found. (ran in 7.9s)

$ flutter test
00:02 +12 -2: Some tests failed.
Failing tests: notes_page_search_test.dart, search_filter_test.dart
```

Hasil per langkah verifikasi jobsheet:

1. **Baca tiap baris** — baris bermasalah: import `../domain/entities/note.dart` (baris 4) dan percabangan empty state di `data:` (dua cabang terner menghasilkan teks yang sama).
2. **Cek import antar layer** — `grep` pada `domain/` membuktikan tidak ada import Flutter/Dio/SQLite di entity, repository, maupun use case. Pelanggaran justru di arah lain: `test/search_filter_test.dart` mengimpor `presentation/pages/notes_page.dart` hanya untuk menguji `filterNotes`, artinya logika bisnis tertahan di layer presentation.
3. **Cek API nyata** — `AsyncValue.when`, `noteRepositoryProvider.overrideWithValue`, `PreferredSize` pada `AppBar.bottom`, `TextEditingController`: dicek terhadap kode Minggu 7 dan paket terpasang; semuanya ada (bukan halusinasi nama API). Yang salah adalah **path relatif**, bukan nama API.
4. **`flutter analyze`** — belum nol warning; error lihat §5.
5. **Test sukses + test gagal** — dibuat dan dibuktikan di §6.
6. **Uji manual 3 kondisi** — dilakukan setelah perbaikan (lihat §9).

## 5. Bukti Bug / Halusinasi

### Temuan 1 — Path import relatif fiktif (terbukti, diperbaiki)

Draf menulis:

```dart
import '../domain/entities/note.dart';
```

Bukti bahwa path itu tidak ada (dijalankan di `campus_notify`):

```text
$ ls lib/features/notes/presentation
providers  pages
$ ls lib/features/notes/domain/entities
note.dart
```

`notes_page.dart` berada di `presentation/pages/`, jadi `../domain/...` menunjuk ke `presentation/domain/` yang **tidak pernah ada** di struktur ini. Path benar adalah `../../domain/entities/note.dart`. Ini pola halusinasi jobsheet ("API yang dikarang") versi konkret: path file yang dikarang. `flutter analyze` membuktikannya dengan error `non_type_as_type_argument` (lihat §4). Diperbaiki dengan mengoreksi path import.

### Temuan 2 — Regresi empty state "logika yakin tapi salah" (terbukti lewat test merah)

`NotesPage` versi Minggu 7 menampilkan `Belum ada catatan.` ketika daftar kosong. Draf AI menyatukan semua kondisi kosong menjadi satu pesan `Tidak ada catatan yang cocok.`, bahkan ketika kueri masih kosong (dua cabang ternary-nya teksnya identik). Perilaku lama berubah tanpa diminta — bug nyata, dibuktikan dengan test merah di §6, lalu diperbaiki.

## 6. Debug dengan Test Merah

urutan debug mengikuti langkah jobsheet:

1. **Reproduksi** — buka `NotesPage` dengan daftar catatan kosong dan kueri pencarian kosong. Perilaku lama (Minggu 7): tampil `Belum ada catatan.`. Perilaku draf AI: tampil `Tidak ada catatan yang cocok.` — pesan menyesatkan karena user tidak mengetik apa pun.
2. **Isolasi** — logika filter masih menempel di file widget; dipindah ke use case murni `SearchNotes` (lihat §7) supaya bisa diuji tanpa UI.
3. **Test merah** — test widget baru ditambahkan ke `test/notes_page_search_test.dart`:

```dart
testWidgets('daftar kosong tanpa kueri tetap menampilkan pesan lama', (tester) async {
  await tester.pumpWidget(pageWith(const []));
  await tester.pumpAndSettle();
  expect(find.text('Belum ada catatan.'), findsOneWidget);
});
```

Hasil pada draf AI (sesuai prediksi, terbukti gagal):

```text
$ flutter test
00:03 +17 -1: Some tests failed.
Failing tests:
  test/notes_page_search_test.dart: daftar kosong tanpa kueri tetap menampilkan pesan lama
```

17 test lain lulus, jadi kegagalan terisolasi pada bug regresi empty state — bukan kesalahan infrastruktur test.

4. **Perbaiki kecil** — pada refactor (§7), kondisi `filtered.isEmpty` dipecah: `hasQuery` (kueri terisi) → `Tidak ada catatan yang cocok.`; tanpa kueri → `Belum ada catatan.` sesuai perilaku asli.
5. **Akar masalah** — AI menyatukan dua kondisi kosong yang berbeda maknanya (daftar kosong vs hasil pencarian kosong) menjadi satu cabang dengan teks identik pada kedua sisi ternary. Diperbaiki dengan memisahkan pesan berdasarkan `hasQuery`.

## 7. Refactor ke Layer yang Benar

Struktur akhir sesuai jobsheet `widget (UI saja) -> notifier (state saja) -> use case (aturan filter/search) -> repository (SQLite/Dio)`:

| File | Isi setelah refactor |
|---|---|
| `domain/usecases/search_notes.dart` (baru) | Use case murni `SearchNotes` (class `const`, tanpa import Flutter sama sekali): aturan normalisasi kueri + pencocokan `title` case-insensitive. |
| `presentation/providers/notes_providers.dart` | Menambah `searchNotesProvider` (mendaftarkan use case) dan `searchQueryProvider` (`NotifierProvider<SearchQueryNotifier, String>`) — state kueri pindah ke notifier, memakai pola `Notifier` yang sama dengan `auth_provider.dart` project ini (Riverpod 3). |
| `presentation/pages/notes_page.dart` | Kembali menjadi `ConsumerWidget` UI-only: watch `notesProvider` + `searchQueryProvider` + `searchNotesProvider`; `onChanged` hanya menulis state notifier; pemecahan pesan empty state. |
| `test/search_filter_test.dart` | Dipindah imporannya dari `presentation/pages/notes_page.dart` ke `domain/usecases/search_notes.dart`; ditambah test keempat (query whitespace-only). |

Bukti `grep` sebelum/sesudah (dijalankan di `campus_notify`):

```text
$ grep -rn "package:flutter\|package:dio\|package:sqflite" lib/features/notes/domain/
(tidak ada hasil — domain/ murni Dart, exit=1)

$ grep -rn "sqflite" lib/features/notes/presentation/
(tidak ada hasil — widget tidak menyentuh database, exit=1)

$ grep -n "presentation" test/search_filter_test.dart
(tidak ada hasil — unit test logika kini hanya mengimpor domain, exit=1)
```

Catatan ukuran: draf AI §3.1 panjangnya 103 baris dalam satu file (melebihi batas 80 baris dari prompt; halaman lama hanya 55 baris). Setelah refactor, `notes_page.dart` turun menjadi 80 baris dan logika aturan pindah ke use case yang bisa diuji tanpa widget — ini pemenuhan tantangan refactor "perkecil hasil AI di atas 80 baris".

Verifikasi setelah refactor:

```text
$ flutter analyze
No issues found!

$ flutter test
00:02 +19: All tests passed!
```

Termasuk test merah §6 yang sekarang hijau. Tidak ada test lama yang rusak (12 test baseline tetap lulus).

## 8. AI Review Challenge

Review dilakukan oleh agen AI terpisah (bukan yang menulis kodenya), dengan prompt dari jobsheet:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod 3, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### 8.1 Temuan dan Verifikasi

**Temuan 1 (blocker): `NotesPage` tidak terhubung ke router.**
Klaim: router hanya mendaftarkan `/login`, `/home`, `/pengumuman/:id`; `addNote` tidak dipanggil dari mana pun, jadi fitur search tidak bisa diuji manual di aplikasi.
Verifikasi (bukti grep di `campus_notify`):

```text
$ grep -rn "NotesPage\|notes_page" lib/
lib/features/notes/presentation/pages/notes_page.dart:6   <- hanya definisinya sendiri
lib/features/notes/presentation/pages/notes_page.dart:7
```

Tidak ada file lain di `lib/` yang mengimpor halaman itu. **Terbukti benar** terhadap kode Minggu 7 yang saya copy. Keputusan: diterima sebagian (lihat tabel 8.2) setelah dikonfirmasi ke pemilik proyek, karena uji manual + screenshot jobsheet mustahil tanpa jalur masuk.

**Temuan 2 (blocker): state kueri keep-alive, kolom teks tidak.**
Klaim: `searchQueryProvider` tetap menyimpan kueri setelah halaman ditutup, sedangkan `TextField` tanpa controller kehilangan isinya — saat halaman dibuka lagi, daftar tersaring oleh kueri yang tidak terlihat.
Verifikasi terhadap paket terpasang (bukan tebakan):

```text
$ grep -n "isAutoDispose" .../riverpod-3.4.3/lib/src/providers/notifier/orphan.dart
86:    super.isAutoDispose = false,
$ grep -n "autoDispose" .../riverpod-3.4.3/CHANGELOG.md | head
236:- Instead of `Provider.autoDispose()`, it is now possible to write `Provider(isAutoDispose: true)`
```

Default `NotifierProvider` = keep-alive: **klaim benar** (saya awalnya mengira Riverpod 3 membalak default menjadi autoDispose — ternyata tidak; ini contoh hipotesis AI yang harus dicek ke sumber). Dibuktikan pula dengan test regresi merah:

```text
$ flutter test test/notes_page_search_test.dart
00:02 +3 -1: kueri tidak bocor saat halaman dibuka ulang [E]
```

Diperbaiki dengan `isAutoDispose: true` pada `searchQueryProvider`; test menjadi hijau.

**Temuan 3 (saran): prefix `Exception: ` bocor ke UI.**
Klaim: `notesProvider` melempar `Exception(result.failure!.message)` dan UI merender `Text('$error')`, sehingga user melihat `Exception: Catatan gagal dimuat...`.
Verifikasi: `notes_providers.dart:42` memang `throw Exception(...)`; `notes_page.dart:40` `Text('$error')`. Test `failure repository ditampilkan sebagai pesan ramah` (mencari teks tanpa prefix) **merah pada kode lama**:

```text
Expected: <1>  Actual: <11>   <- dari expect(repo.fetches, 1)
```

Ekspektasi jumlah fetch saya sendiri meleset karena penemuan tambahan: Riverpod 3 punya retry default hingga 10x backoff (`provider_container.dart:983-998`: `maxRetries = 10`, hanya mengecualikan `ProviderException`/`Error`), jadi `1 + 10 = 11` fetch adalah perilaku paket, bukan bug kode search. Assertion diubah menjadi perbandingan perilaku (`greaterThan(before)`). Inti temuan (bocornya `Exception: `) tetap benar dan diperbaiki: provider melempar `Failure` apa adanya, UI menampilkan `error.message` lewat `error is Failure`.

### 8.2 Tabel Usulan AI vs Keputusan Akhir

| Usulan AI | Keputusan akhir | Alasan teknis |
|---|---|---|
| Tambah route `/notes`, navigasi dari Home, FAB input catatan (Temuan 1) | **Terima (minim)** | Uji manual + screenshot jobsheet butuh jalur masuk; route dan tombol mengikuti pola go_router yang sudah ada. |
| Buat use case `AddNote` baru (Temuan 1) | **Tolak** | Kontrak `NoteRepository.addNote` sudah ada dan ter-implementasi sejak Minggu 7; menambah use case baru tidak diminta jobsheet Minggu 9 dan memperbesar diff di luar fitur search. |
| Tambah widget test navigasi router (Temuan 1) | **Tolak** | Di luar lingkup test jobsheet (unit search + widget empty state); halaman sudah tercover lewat test yang mount `NotesPage` langsung. |
| Opsi (b) fix Temuan 2: `ConsumerStatefulWidget` + `TextEditingController` di-seed dari provider + listener dua arah | **Tolak** | Meniru dua sumber kebenaran (controller dan provider) untuk satu state; opsi (a) `isAutoDispose: true` menyamakan siklus hidup provider dengan halaman sehingga state hilang bersama widget-nya — lebih kecil dan tanpa duplikasi. |
| Opsi (a) fix Temuan 2: `NotifierProvider(..., isAutoDispose: true)` | **Terima + buktikan** | API diverifikasi di sumber paket; test regresi merah→hijau. |
| Opsi fix Temuan 3: `Failure implements Exception` + `throw result.failure!` | **Terima + refactor** | `implements Exception` tidak diperlukan: AsyncValue menerima objek error apa pun; cukup throw `Failure` lalu UI memeriksa `error is Failure`. |
| Assertion test `fetches == 1 → 2` | **Tolak setelah diuji** | Bertentangan dengan default retry paket (maxRetries=10); assertion eksak rapuh, diganti perbandingan sebelum/sesudah tap. |

### 8.3 Keputusan per File

| File | Keputusan |
|---|---|
| `domain/usecases/search_notes.dart` | **Terima** (usulan awal AI sudah sesuai: murni Dart, tanpa Flutter/Dio/SQLite — dibuktikan grep §7). |
| `presentation/pages/notes_page.dart` | **Terima + refactor**: draf AI dipindah logikanya ke use case (regresi empty state §6), pesan error distruktur (temuan 3), FAB dipasang (temuan 1). |
| `presentation/providers/notes_providers.dart` | **Terima + refactor**: `searchQueryProvider` + `isAutoDispose` (temuan 2), `throw result.failure!` (temuan 3). |
| `presentation/widgets/add_note_sheet.dart` | **Tulis manual** mengikuti pola existing (bottom sheet + validasi judul seperti Minggu 8), bukan hasil AI; AI hanya menyarankan keberadaannya. |
| `router.dart`, `routes.dart`, `pages/home_page.dart` | **Terima sebagian**: hanya wiring route/navigasi (temuan 1), tanpa mengubah redirect/auth yang sudah ada. |
| `test/search_filter_test.dart` | **Terima + refactor** (impor dipindah ke domain, §7). |
| `test/notes_page_search_test.dart` | **Terima + tambah**: 2 test regresi dari temuan 2/3, assertion retry direvisi. |

Setiap keputusan di atas bisa dijelaskan tanpa membuka AI: path import (struktur folder nyata), `isAutoDispose` (sumber paket + CHANGELOG), prefix Exception (`toString()` objek `Exception`), retry 10x (fungsi `defaultRetry`), dan wiring route (syarat uji manual jobsheet).

## 9. Verifikasi Akhir

Pemeriksaan mesin terakhir pada `campus_notify` (Minggu 9):

```text
$ flutter analyze
No issues found! (ran in 6.1s)

$ dart format --set-exit-if-changed .
Formatted 31 files (0 changed)

$ flutter test
00:05 +21: All tests passed!
```

### 9.1 Uji manual tiga kondisi (perangkat Android CPH2473)

Aplikasi debug di-install ke perangkat, lalu dijalankan alur: login (email `test@demo.id`) → Home → Buka Catatan → tambah 3 catatan lewat FAB ("Belanja bulanan", "Rencana belanja buku", "Tugas pemrograman") → ketik kueri di kolom pencarian. Hasil diverifikasi lewat uiautomator dump dan screenshot (folder `screenshots/`):

| Kondisi | Kueri | Hasil di layar | Bukti |
|---|---|---|---|
| Query kosong | (kosong) | Daftar penuh 3 catatan, urutan terbaru dulu | `01-query-kosong-daftar.png` |
| Query cocok | `belanja` (huruf kecil) | 2 hasil: "Rencana belanja buku", "Belanja bulanan" — sekaligus membuktikan pencarian tidak case-sensitive di UI | `02-query-cocok-hasil.png` |
| Query tidak cocok | `zzz-tak-cocok` | Empty state "Tidak ada catatan yang cocok." | `03-query-tak-cocok-empty-state.png` |

Fungsi lama tidak rusak: login/logout, halaman pengumuman, empty state lama "Belum ada catatan." (dilihat saat daftar masih kosong sebelum ada catatan ditambahkan), dan snackbar "Catatan tersimpan" setelah simpan.

Catatan transparansi: navigasi uji manual dilakukan lewat adb (`input tap`/`input text`) pada aplikasi yang berjalan di HP (terlihat di jendela scrcpy), bukan ketikan jari langsung; setiap langkah diverifikasi dengan dump hierarki UI sebelum screenshot diambil.

## 10. Refleksi

Jawaban di bawah merangkum apa yang benar-benar terjadi pada pengerjaan ini — silakan Anda sesuaikan dengan pengalaman sendiri sebelum commit.

1. **Halusinasi AI yang ditemukan:** path import `../domain/entities/note.dart` yang tidak ada di struktur folder nyata (harusnya `../../domain/...`), dibuktikan oleh 3 error `flutter analyze`; plus regresi empty state "logika yakin tapi salah" yang dibuktikan test merah `+17 -1`.
2. **Prompt paling membantu:** slot Batas ("jangan ubah arsitektur, jangan panggil SQLite dari widget, maks 80 baris") — justru dari situlah temuan verifikasi paling banyak muncul (draf melanggar batas 80 baris dan menaruh logika di presentation, sehingga arah refactor jelas). Yang akan diubah: menyebut perilaku lama yang harus dipertahankan (pesan "Belum ada catatan.") supaya tidak hilang saat AI menulis ulang halaman.
3. **Refactor pada kode AI:** memindahkan `filterNotes` dari file widget ke use case domain murni `SearchNotes`, memindahkan state kueri dari `setState` lokal ke `NotifierProvider` dengan `isAutoDispose: true`.
4. **Keputusan tersulit:** temuan review AI #1 (route `/notes` tidak ada). Faktanya benar, tapi menambah route + FAB berarti menyentuh file di luar fitur search — diputuskan terima-minim karena tanpa itu uji manual jobsheet tidak mungkin dijalankan, sambil menolak usulan AddNote use case baru dan router test sebagai di luar scope.
