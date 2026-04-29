import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

/// Acesso singleton ao SQLite local.
///
/// Convencionando uma única instância aberta em todo o app: o `Lock`
/// previne múltiplas aberturas concorrentes (chamadas paralelas a
/// `database` durante o cold start). A doc oficial do tekartik/sqflite
/// recomenda exatamente esse padrão.
class LocalDatabase {
  LocalDatabase();

  static const _filename = 'mamba_growth.db';
  static const _version = 1;

  Database? _db;
  final Lock _lock = Lock();

  Future<Database> get database async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    return _lock.synchronized(() async {
      final cached = _db;
      if (cached != null && cached.isOpen) return cached;
      final fresh = await _open();
      _db = fresh;
      return fresh;
    });
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _filename);
    return openDatabase(
      path,
      version: _version,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fasts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        start_at      INTEGER NOT NULL,
        end_at        INTEGER,
        target_hours  INTEGER NOT NULL,
        eating_hours  INTEGER NOT NULL,
        completed     INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_fasts_active ON fasts(end_at) WHERE end_at IS NULL',
    );
    await db.execute(
      'CREATE INDEX idx_fasts_start ON fasts(start_at DESC)',
    );
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _lock.synchronized(() async {
      final db = _db;
      if (db != null && db.isOpen) {
        await db.close();
      }
      _db = null;
    });
  }
}
