# Verifikasi AI Challenge

## AI yang Digunakan

Claude

## Hasil Verifikasi

Setelah hasil dari Claude diperiksa, perbandingan antara SharedPreferences,
Hive, sqflite, dan Drift sudah cukup sesuai dengan kebutuhan aplikasi
Offline Notes.

SharedPreferences cocok digunakan untuk menyimpan data sederhana seperti
Dark Mode karena hanya membutuhkan penyimpanan key-value.

Untuk data catatan, penggunaan database seperti sqflite atau Drift lebih
sesuai karena dapat menyimpan banyak data dan mendukung query.

Namun, terdapat kekurangan pada schema yang diberikan oleh AI. Schema
tersebut sudah memiliki `updated_at`, tetapi belum memiliki field `dirty`.

Field `dirty` dibutuhkan untuk menandai apakah catatan sudah
tersinkronisasi atau belum.

## Tabel Perbandingan Final

| Kriteria | SharedPreferences | Hive | sqflite | Drift |
|---|---|---|---|---|
| Query | Sederhana | Terbatas | SQL lengkap | SQL + query builder |
| Relasi | Tidak ada | Terbatas | Mendukung | Mendukung |
| Stream | Tidak bawaan | Ada | Tidak bawaan | Ada |
| Type Safety | Terbatas | Sedang | Rendah | Tinggi |
| Boilerplate | Sedikit | Sedikit-Sedang | Sedang | Sedang |
| Testing | Mudah | Mudah | Sedang | Sedang |

## Perbaikan Schema

Schema awal dari AI belum memiliki field `dirty`. Setelah diperiksa,
schema yang sesuai dengan kebutuhan Offline Notes adalah:

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);