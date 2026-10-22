
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final databasePath = await getDatabasesPath();

  return openDatabase(
    '$databasePath/notes.db',
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}
