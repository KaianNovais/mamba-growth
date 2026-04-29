import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository_local.dart';
import 'package:mamba_growth/data/services/database/local_database.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MealsRepositoryLocal', () {
    late LocalDatabase localDb;
    late MealsRepositoryLocal repo;

    setUp(() async {
      localDb = LocalDatabase(pathOverride: inMemoryDatabasePath);
      repo = MealsRepositoryLocal(database: localDb);
      while (!repo.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    });

    tearDown(() async {
      repo.dispose();
      await localDb.close();
    });

    test('addMeal persiste e dispara stream do dia', () async {
      final today = DateTime.now();
      final stream = repo.watchMealsForDay(today);
      final result = await repo.addMeal(name: 'Almoço', calories: 620);
      expect(result, isA<Ok<Meal>>());

      final emitted = await stream.firstWhere((list) => list.isNotEmpty);
      expect(emitted.first.name, 'Almoço');
      expect(emitted.first.calories, 620);
    });

    test('rejeita nome vazio', () async {
      final r = await repo.addMeal(name: '   ', calories: 100);
      expect(r, isA<Error<Meal>>());
    });

    test('rejeita calories fora do range', () async {
      expect(await repo.addMeal(name: 'x', calories: 0), isA<Error<Meal>>());
      expect(await repo.addMeal(name: 'x', calories: -1), isA<Error<Meal>>());
      expect(
        await repo.addMeal(name: 'x', calories: 10000),
        isA<Error<Meal>>(),
      );
    });

    test('watchMealsForDay filtra apenas o dia pedido', () async {
      final db = await localDb.database;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await db.insert('meals', {
        'name': 'Velha',
        'calories': 400,
        'eaten_at': yesterday.millisecondsSinceEpoch,
      });

      await repo.addMeal(name: 'Hoje', calories: 500);
      final list = await repo.watchMealsForDay(DateTime.now()).first;
      expect(list.length, 1);
      expect(list.first.name, 'Hoje');
    });

    test('updateMeal altera nome e calorias', () async {
      final ok = await repo.addMeal(name: 'A', calories: 100);
      final meal = (ok as Ok<Meal>).value;
      final updated = await repo.updateMeal(
        meal.copyWith(name: 'B', calories: 200),
      );
      expect(updated, isA<Ok<Meal>>());
      final list = await repo.watchMealsForDay(DateTime.now()).first;
      expect(list.first.name, 'B');
      expect(list.first.calories, 200);
    });

    test('deleteMeal remove e stream re-emite', () async {
      final ok = await repo.addMeal(name: 'X', calories: 100);
      final meal = (ok as Ok<Meal>).value;
      await repo.deleteMeal(meal.id);
      final list = await repo.watchMealsForDay(DateTime.now()).first;
      expect(list, isEmpty);
    });

    test('reinsertMeal restaura', () async {
      final ok = await repo.addMeal(name: 'X', calories: 100);
      final meal = (ok as Ok<Meal>).value;
      await repo.deleteMeal(meal.id);
      final r = await repo.reinsertMeal(meal);
      expect(r, isA<Ok<Meal>>());
      final list = await repo.watchMealsForDay(DateTime.now()).first;
      expect(list.length, 1);
      expect(list.first.name, 'X');
    });

    test('setGoal e clearGoal espelham em currentGoal e listenable', () async {
      expect(repo.currentGoal, isNull);
      var changes = 0;
      repo.goalListenable.addListener(() => changes++);

      await repo.setGoal(2000);
      expect(repo.currentGoal, 2000);
      expect(changes, 1);

      await repo.setGoal(2500);
      expect(repo.currentGoal, 2500);

      await repo.clearGoal();
      expect(repo.currentGoal, isNull);
    });

    test('setGoal valida range 500..9999', () async {
      expect(() => repo.setGoal(499), throwsArgumentError);
      expect(() => repo.setGoal(10000), throwsArgumentError);
    });

    test('persistência entre instâncias do repo', () async {
      await repo.setGoal(1800);
      await repo.addMeal(name: 'X', calories: 200);
      repo.dispose();

      final repo2 = MealsRepositoryLocal(database: localDb);
      while (!repo2.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
      expect(repo2.currentGoal, 1800);
      final list = await repo2.watchMealsForDay(DateTime.now()).first;
      expect(list.length, 1);
      repo2.dispose();
    });
  });
}
