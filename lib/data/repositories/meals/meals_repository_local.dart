import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../domain/models/meal.dart';
import '../../../utils/result.dart';
import '../../services/database/local_database.dart';
import 'meals_repository.dart';

class MealsRepositoryLocal extends MealsRepository {
  MealsRepositoryLocal({required LocalDatabase database})
      : _localDb = database {
    _bootstrap();
  }

  static const _goalKey = 'daily_calorie_goal';
  static const _minGoal = 500;
  static const _maxGoal = 9999;
  static const _maxNameLen = 60;
  static const _maxCalories = 9999;

  final LocalDatabase _localDb;
  bool _isInitialized = false;

  final ValueNotifier<int?> _goal = ValueNotifier<int?>(null);

  // Cache + broadcast por dia. _currentDay = início do dia (00:00 local).
  DateTime? _currentDay;
  List<Meal> _todayCache = const [];
  final StreamController<List<Meal>> _todayCtrl =
      StreamController<List<Meal>>.broadcast();
  bool _isDisposed = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  ValueListenable<int?> get goalListenable => _goal;

  @override
  int? get currentGoal => _goal.value;

  Future<void> _bootstrap() async {
    try {
      final db = await _localDb.database;
      _goal.value = await _readGoal(db);
      _currentDay = _startOfDay(DateTime.now());
      await _refreshDay(db);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  Future<int?> _readGoal(Database db) async {
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_goalKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return int.tryParse((rows.first['value'] as String?) ?? '');
  }

  Future<void> _refreshDay(Database db) async {
    final day = _currentDay!;
    final start = day.millisecondsSinceEpoch;
    final end = day.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final rows = await db.query(
      'meals',
      where: 'eaten_at >= ? AND eaten_at < ?',
      whereArgs: [start, end],
      orderBy: 'eaten_at DESC',
    );
    _todayCache = List.unmodifiable(rows.map(_fromRow));
    if (!_todayCtrl.isClosed) _todayCtrl.add(_todayCache);
  }

  Meal _fromRow(Map<String, Object?> row) => Meal(
        id: row['id'] as int,
        name: row['name'] as String,
        calories: row['calories'] as int,
        eatenAt: DateTime.fromMillisecondsSinceEpoch(row['eaten_at'] as int),
      );

  @override
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'meals',
      where: 'eaten_at >= ? AND eaten_at < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'eaten_at DESC',
    );
    return List.unmodifiable(rows.map(_fromRow));
  }

  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) async* {
    final requested = _startOfDay(day);
    if (_currentDay == null || requested != _currentDay) {
      _currentDay = requested;
      final db = await _localDb.database;
      await _refreshDay(db);
    }
    yield _todayCache;
    yield* _todayCtrl.stream;
  }

  @override
  Future<Result<Meal>> addMeal({
    required String name,
    required int calories,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > _maxNameLen) {
      return const Result.error(MealsException('Nome inválido.'));
    }
    if (calories < 1 || calories > _maxCalories) {
      return const Result.error(MealsException('Calorias inválidas.'));
    }
    try {
      final now = DateTime.now();
      final db = await _localDb.database;
      final id = await db.insert('meals', {
        'name': trimmed,
        'calories': calories,
        'eaten_at': now.millisecondsSinceEpoch,
      });
      final meal = Meal(
        id: id,
        name: trimmed,
        calories: calories,
        eatenAt: now,
      );
      _currentDay = _startOfDay(now);
      await _refreshDay(db);
      return Result.ok(meal);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<Meal>> updateMeal(Meal meal) async {
    final trimmed = meal.name.trim();
    if (trimmed.isEmpty || trimmed.length > _maxNameLen) {
      return const Result.error(MealsException('Nome inválido.'));
    }
    if (meal.calories < 1 || meal.calories > _maxCalories) {
      return const Result.error(MealsException('Calorias inválidas.'));
    }
    try {
      final db = await _localDb.database;
      await db.update(
        'meals',
        {'name': trimmed, 'calories': meal.calories},
        where: 'id = ?',
        whereArgs: [meal.id],
      );
      await _refreshDay(db);
      return Result.ok(meal.copyWith(name: trimmed));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteMeal(int id) async {
    try {
      final db = await _localDb.database;
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);
      await _refreshDay(db);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<Meal>> reinsertMeal(Meal meal) async {
    try {
      final db = await _localDb.database;
      final id = await db.insert('meals', {
        'name': meal.name,
        'calories': meal.calories,
        'eaten_at': meal.eatenAt.millisecondsSinceEpoch,
      });
      await _refreshDay(db);
      return Result.ok(meal.copyWith(id: id));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<void> setGoal(int kcal) async {
    if (kcal < _minGoal || kcal > _maxGoal) {
      throw ArgumentError('kcal fora do range $_minGoal..$_maxGoal');
    }
    final db = await _localDb.database;
    await db.insert(
      'settings',
      {'key': _goalKey, 'value': kcal.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _goal.value = kcal;
    notifyListeners();
  }

  @override
  Future<void> clearGoal() async {
    final db = await _localDb.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [_goalKey]);
    _goal.value = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _todayCtrl.close();
    _goal.dispose();
    super.dispose();
  }
}
