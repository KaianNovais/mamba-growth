import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/services/database/local_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalDatabase', () {
    late LocalDatabase localDb;

    setUp(() async {
      localDb = LocalDatabase(pathOverride: inMemoryDatabasePath);
    });

    tearDown(() async {
      await localDb.close();
    });

    test('cria tabelas fasts, settings e meals em schema v2', () async {
      final db = await localDb.database;
      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      ))
          .map((r) => r['name'] as String)
          .toSet();
      expect(tables, containsAll(['fasts', 'settings', 'meals']));
    });

    test('meals tem CHECK calories > 0', () async {
      final db = await localDb.database;
      expect(
        () => db.insert('meals', {
          'name': 'x',
          'calories': 0,
          'eaten_at': DateTime.now().millisecondsSinceEpoch,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('insert + query simples', () async {
      final db = await localDb.database;
      final id = await db.insert('meals', {
        'name': 'Almoço',
        'calories': 620,
        'eaten_at': 1000,
      });
      expect(id, isPositive);
      final rows = await db.query('meals');
      expect(rows.first['name'], 'Almoço');
    });
  });
}
