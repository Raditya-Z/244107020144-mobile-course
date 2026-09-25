# Output Awal AI Challenge

## AI yang Digunakan

Claude

# Perbandingan SharedPreferences vs Hive vs sqflite vs Drift

## Untuk kebutuhan preferensi tema (key-value sederhana)

| Kriteria | SharedPreferences | Hive |
|---|---|---|
| Kompleksitas query | Tidak ada query, hanya get/set by key | Tidak ada query kompleks, get/set by key/index |
| Kebutuhan relasi | Tidak relevan | Tidak relevan |
| Reaktivitas (stream) | Tidak ada (butuh listener manual/polling) | Ada (`Box.watch()` / `ValueListenableBuilder`) |
| Type-safety | Lemah (String/bool/int/double/List\<String\> saja) | Kuat (TypeAdapter, bisa simpan objek custom) |
| Boilerplate | Sangat kecil | Kecil–sedang (perlu generate adapter kalau simpan objek) |
| Testing | Mudah (mock via `SharedPreferences.setMockInitialValues`) | Mudah (bisa pakai `Hive.init` di temp dir saat test) |

**Untuk preferensi tema saja (satu-dua flag sederhana), SharedPreferences sudah cukup** — overhead Hive tidak sepadan untuk kasus sesederhana ini, kecuali project sudah pakai Hive untuk hal lain juga.

## Untuk kebutuhan catatan (CRUD, list, 1000+ item)

| Kriteria | Hive | sqflite | Drift |
|---|---|---|---|
| Kompleksitas query | Terbatas (filter manual di Dart, tidak ada query engine) | Penuh (raw SQL, JOIN, WHERE, ORDER BY, agregasi) | Penuh + query builder type-safe (kompilasi ke SQL) |
| Kebutuhan relasi | Lemah (harus simpan ID manual & resolve sendiri) | Native (FK, JOIN) | Native + relasi dicek saat compile-time |
| Reaktivitas (stream) | Ada (`box.watch()`), tapi granular per-box | Tidak ada bawaan (perlu library tambahan) | Ada, built-in (`.watch()` mengembalikan `Stream` otomatis re-query saat data berubah) |
| Type-safety | Sedang (TypeAdapter manual, rawan drift versi skema) | Rendah (raw SQL string, error baru ketahuan saat runtime) | Tinggi (generated code, error query ketahuan saat compile) |
| Ukuran boilerplate | Kecil–sedang (adapter generation) | Sedang–besar (helper class, mapper manual ke/dari Map) | Sedang (tabel didefinisikan sekali, sisanya digenerate lewat build_runner) |
| Kemudahan testing | Mudah (in-memory/temp box) | Sedang (perlu `sqflite_common_ffi` untuk unit test di luar device) | Sedang (bisa pakai `NativeDatabase.memory()`, mudah di-mock) |

Untuk **1000+ catatan** dengan kemungkinan fitur pencarian, filter kategori/tag, sorting, atau nanti ditambah relasi (misal notes-to-tags many-to-many), performa dan ekspresivitas query jadi faktor penentu:
- **Hive** unggul di kecepatan baca/tulis key-value sederhana, tapi begitu butuh query (search by keyword, filter by date range, sort by multiple field) kamu harus load semua ke memori lalu filter manual di Dart — tidak scalable secara query, walau untuk 1000 item masih "kepakai".
- **sqflite** memberi kekuatan SQL penuh tapi kamu menulis SQL string manual, rawan typo, tidak ada compile-time check, dan mapping row↔object dilakukan manual.
- **Drift** memberi kekuatan SQL + type-safety compile-time + stream reaktif otomatis — cocok kalau app akan berkembang (tag, kategori, full-text search, dsb).

## Rekomendasi Final

| Kebutuhan | Rekomendasi | Alasan |
|---|---|---|
| Preferensi tema | **SharedPreferences** | Key-value sesederhana theme mode tidak butuh query/relasi/reaktivitas kompleks; boilerplate minimal, langsung pakai |
| Catatan (CRUD, 1000+ item) | **Drift (di atas sqflite)** | Butuh query (search/filter/sort), reaktivitas stream untuk update UI real-time, type-safety mencegah bug SQL, dan siap kalau nanti ditambah relasi (tags/kategori) tanpa refactor besar |

Kalau scope app dipastikan **tidak akan pernah** butuh query kompleks atau relasi (murni CRUD flat list, tanpa search/filter), Hive juga valid sebagai pilihan lebih ringan dan boilerplate lebih kecil dari Drift — tapi kalau ada kemungkinan fitur search/filter/kategori di roadmap, Drift lebih aman jangka panjang.

## Skema untuk 1000+ Catatan

**Drift (tabel SQL, dengan definisi Dart):**

```dart
// notes_table.dart
import 'package:drift/drift.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();
  TextColumn get category => text().nullable()(); // atau relasi FK ke Categories
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Index untuk mempercepat sort/filter pada 1000+ baris
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  // ...
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_notes_updated ON notes(updated_at DESC)',
      );
      await customStatement(
        'CREATE INDEX idx_notes_pinned ON notes(is_pinned)',
      );
    },
  );
}
```

**sqflite (setara, raw SQL):**

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  is_pinned INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_notes_updated ON notes(updated_at DESC);
CREATE INDEX idx_notes_pinned ON notes(is_pinned);
```

**Hive (box + typed object, tanpa index — semua load ke memori):**

```dart
@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late String content;

  @HiveField(2)
  String? category;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  bool isPinned = false;
}

// Box dibuka sebagai: Hive.openBox<NoteModel>('notes')
// Sort/filter 1000+ item = box.values.where(...).toList()..sort(...) di Dart
```

## Ringkasan Trade-off

- **SharedPreferences**: paling ringan, tapi hanya untuk data flat sederhana (bool/string/int); tidak cocok untuk list objek atau data yang tumbuh.
- **Hive**: cepat untuk baca/tulis key-value dan objek sederhana, punya stream reaktif per-box, tapi query terbatas — filter/sort harus manual di memori, jadi makin berat kalau data dan kompleksitas filter bertambah.
- **sqflite**: paling fleksibel secara SQL murni dan sudah battle-tested, tapi tidak ada type-safety (string SQL rawan salah), tidak ada reaktivitas bawaan, dan mapping manual bikin boilerplate lumayan besar.
- **Drift**: kombinasi terbaik untuk kasus catatan yang berpotensi kompleks — SQL power + compile-time safety + stream reaktif otomatis — dengan biaya setup awal (code generation, sedikit lebih curam kurva belajarnya) dibanding Hive/sqflite polos.