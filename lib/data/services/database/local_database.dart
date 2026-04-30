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
  LocalDatabase({String? pathOverride}) : _pathOverride = pathOverride;

  static const _filename = 'mamba_growth.db';
  static const _version = 2;

  final String? _pathOverride;
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
    final path = _pathOverride ?? p.join(await getDatabasesPath(), _filename);
    return openDatabase(
      path,
      version: _version,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
    await _createMealsTable(db);
  }

  Future<void> _onUpgrade(Database db, int from, int to) async {
    if (from < 2) {
      await _createMealsTable(db);
    }
  }

  Future<void> _createMealsTable(Database db) async {
    await db.execute('''
      CREATE TABLE meals (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT    NOT NULL,
        calories  INTEGER NOT NULL CHECK (calories > 0),
        eaten_at  INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_meals_eaten_at ON meals(eaten_at DESC)',
    );
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
