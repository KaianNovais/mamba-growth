# Meals (Calorias) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar feature de registro de calorias: tela "hoje" com anel de progresso, modal de adicionar/editar refeição, exclusão com undo, e seção de meta diária no perfil.

**Architecture:** `MealsRepository` (sqflite) injetado em `main.dart` via `ChangeNotifierProvider`. `MealsViewModel` expõe estado derivado (`totalKcal`, `progress`, `overGoal`) via `Command0/1`. UI reaproveita `ProgressRing` (refator do `FastingRing`) parametrizado por cor. Migration v1→v2 cria a tabela `meals`. Meta vive na tabela `settings` existente.

**Tech Stack:** Flutter + Dart 3.11, `provider` 6.1.5 (ChangeNotifier), `sqflite` 2.4.2 (+`sqflite_common_ffi` para testes), `flutter_test`, `fake_async`.

**Spec de referência:** `docs/superpowers/specs/2026-04-29-meals-calorie-tracking-design.md`.

---

## File Structure

**Criados:**
- `lib/ui/core/widgets/progress_ring.dart` — anel genérico, parametrizado por cor + overflow
- `lib/domain/models/meal.dart` — value object imutável
- `lib/data/repositories/meals/meals_repository.dart` — abstract ChangeNotifier
- `lib/data/repositories/meals/meals_repository_local.dart` — sqflite-backed
- `lib/ui/meals/view_models/meals_view_model.dart` — estado derivado + Commands
- `lib/ui/meals/widgets/meal_list_item.dart` — card de refeição
- `lib/ui/meals/widgets/add_meal_sheet.dart` — modal criar/editar
- `lib/ui/profile/widgets/calorie_goal_sheet.dart` — modal definir/remover meta
- `test/domain/meal_test.dart`
- `test/data/repositories/meals_repository_local_test.dart`
- `test/ui/meals_view_model_test.dart`
- `test/ui/meals_screen_test.dart`
- `test/ui/add_meal_sheet_test.dart`
- `test/ui/calorie_goal_sheet_test.dart`

**Modificados:**
- `lib/ui/core/themes/app_colors.dart` — adiciona `accentWarm` (#E08A4C)
- `lib/data/services/database/local_database.dart` — version 2, onUpgrade, tabela `meals`
- `lib/ui/home/widgets/home_screen.dart` — usa `ProgressRing` com cor explícita
- `lib/ui/home/widgets/fasting_ring.dart` — **deletado** (substituído)
- `lib/ui/meals/widgets/meals_screen.dart` — implementação completa (era placeholder)
- `lib/ui/profile/widgets/profile_screen.dart` — adiciona seção "Calorias"
- `lib/main.dart` — registra `MealsRepositoryLocal` no `MultiProvider`
- `lib/l10n/app_en.arb` + `app_pt.arb` — strings novas
- `pubspec.yaml` — `sqflite_common_ffi` em `dev_dependencies`

---

## Task 1: Refator FastingRing → ProgressRing genérico

**Files:**
- Create: `lib/ui/core/widgets/progress_ring.dart`
- Modify: `lib/ui/core/themes/app_colors.dart` (add `accentWarm`)
- Modify: `lib/ui/home/widgets/home_screen.dart:17` (import) e usos
- Delete: `lib/ui/home/widgets/fasting_ring.dart`

- [ ] **Step 1.1: Adicionar `accentWarm` ao AppColors**

Edit `lib/ui/core/themes/app_colors.dart` — adicionar campo no construtor, no preset `dark`, no `copyWith`, e no `lerp`:

```dart
// no construtor:
required this.accentWarm,
// nos campos:
final Color accentWarm;
// no preset dark, depois de accentDim:
accentWarm: Color(0xFFE08A4C),
// no copyWith:
Color? accentWarm,
// e dentro:
accentWarm: accentWarm ?? this.accentWarm,
// no lerp:
accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
```

- [ ] **Step 1.2: Criar `ProgressRing` em core/widgets**

Create `lib/ui/core/widgets/progress_ring.dart` — copia integral do `fasting_ring.dart` mas:
- Renomeia classe para `ProgressRing` e `_ProgressRingState`
- Adiciona parâmetros `Color? color` e `Color? overflowColor`
- O painter aceita `progress` 0..∞; clamp para 0..1 vira `mainProgress`, e `overflowProgress = (progress - 1).clamp(0, 1)` é desenhado por cima em `overflowColor`
- `child` continua opcional

Implementação mínima nova no painter (substitui o bloco `if (progress <= 0) return;`):

```dart
final mainProgress = progress.clamp(0.0, 1.0);
final overflowProgress = (progress - 1.0).clamp(0.0, 1.0);

// desenha arco principal igual ao código atual, mas usando mainProgress
// no lugar de progress.

// se overflowProgress > 0, desenha um segundo arco por cima
// começando em start, com sweep = 2π * overflowProgress, em overflowColor.
```

No `build()` do widget:

```dart
final colors = context.colors;
final main = widget.color ?? colors.accent;
final overflow = widget.overflowColor ?? colors.accentWarm;
// passa pro painter
```

- [ ] **Step 1.3: Atualizar Home pra usar ProgressRing**

Edit `lib/ui/home/widgets/home_screen.dart`:

```dart
// linha 17, antes:
import 'fasting_ring.dart';
// depois:
import '../../core/widgets/progress_ring.dart';
```

E todas as ocorrências de `FastingRing(` viram `ProgressRing(`.

- [ ] **Step 1.4: Deletar fasting_ring.dart**

```bash
rm lib/ui/home/widgets/fasting_ring.dart
```

- [ ] **Step 1.5: Rodar análise + testes existentes**

```bash
flutter analyze
flutter test
```

Esperado: `No issues found!` + todos os testes passam.

- [ ] **Step 1.6: Commit**

```bash
git add lib/ui/core/themes/app_colors.dart lib/ui/core/widgets/progress_ring.dart lib/ui/home/widgets/home_screen.dart lib/ui/home/widgets/fasting_ring.dart
git commit -m "refactor(ui): extract ProgressRing from FastingRing with parametric colors"
```

---

## Task 2: Domain model `Meal`

**Files:**
- Create: `lib/domain/models/meal.dart`
- Test: `test/domain/meal_test.dart`

- [ ] **Step 2.1: Escrever teste**

Create `test/domain/meal_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/meal.dart';

void main() {
  group('Meal', () {
    final eatenAt = DateTime.utc(2026, 4, 29, 12, 30);
    final base = Meal(
      id: 1,
      name: 'Almoço',
      calories: 620,
      eatenAt: eatenAt,
    );

    test('expõe campos imutáveis', () {
      expect(base.id, 1);
      expect(base.name, 'Almoço');
      expect(base.calories, 620);
      expect(base.eatenAt, eatenAt);
    });

    test('copyWith substitui apenas o que recebe', () {
      final renamed = base.copyWith(name: 'Almoço leve');
      expect(renamed.id, base.id);
      expect(renamed.name, 'Almoço leve');
      expect(renamed.calories, base.calories);
      expect(renamed.eatenAt, base.eatenAt);
    });

    test('igualdade por valor', () {
      final twin = Meal(id: 1, name: 'Almoço', calories: 620, eatenAt: eatenAt);
      expect(base, equals(twin));
      expect(base.hashCode, twin.hashCode);
    });
  });
}
```

- [ ] **Step 2.2: Rodar (deve falhar)**

```bash
flutter test test/domain/meal_test.dart
```

Esperado: erro de compilação `Target of URI doesn't exist: 'package:mamba_growth/domain/models/meal.dart'`.

- [ ] **Step 2.3: Implementar `Meal`**

Create `lib/domain/models/meal.dart`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.eatenAt,
  });

  final int id;
  final String name;
  final int calories;
  final DateTime eatenAt;

  Meal copyWith({
    int? id,
    String? name,
    int? calories,
    DateTime? eatenAt,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      eatenAt: eatenAt ?? this.eatenAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meal &&
        other.id == id &&
        other.name == name &&
        other.calories == calories &&
        other.eatenAt == eatenAt;
  }

  @override
  int get hashCode => Object.hash(id, name, calories, eatenAt);
}
```

- [ ] **Step 2.4: Rodar (deve passar)**

```bash
flutter test test/domain/meal_test.dart
```

Esperado: 3 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add lib/domain/models/meal.dart test/domain/meal_test.dart
git commit -m "feat(meals): add Meal domain model"
```

---

## Task 3: Database migration v1 → v2 (tabela `meals`)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/data/services/database/local_database.dart`
- Test: `test/data/local_database_test.dart`

- [ ] **Step 3.1: Adicionar `sqflite_common_ffi` em dev_dependencies**

Edit `pubspec.yaml`, na seção `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.4
  sqflite_common_ffi: ^2.3.5
  fake_async: ^1.3.1
```

(`fake_async` já está implícito — explicitar evita problemas; se já estiver, OK manter).

Run:

```bash
flutter pub get
```

- [ ] **Step 3.2: Escrever teste de migration**

Create `test/data/local_database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mamba_growth/data/services/database/local_database.dart';

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
```

- [ ] **Step 3.3: Rodar (deve falhar)**

```bash
flutter test test/data/local_database_test.dart
```

Esperado: falha — `LocalDatabase` ainda não aceita `pathOverride`, schema ainda não tem `meals`.

- [ ] **Step 3.4: Atualizar `LocalDatabase`**

Edit `lib/data/services/database/local_database.dart`:

```dart
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
```

- [ ] **Step 3.5: Rodar (deve passar)**

```bash
flutter test test/data/local_database_test.dart
```

Esperado: 3 tests pass.

- [ ] **Step 3.6: Rodar suíte inteira pra garantir que migration não quebrou ninguém**

```bash
flutter test
```

Esperado: tudo verde.

- [ ] **Step 3.7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/services/database/local_database.dart test/data/local_database_test.dart
git commit -m "feat(db): add meals table and v2 migration"
```

---

## Task 4: `MealsRepository` (interface) e `MealsRepositoryLocal`

**Files:**
- Create: `lib/data/repositories/meals/meals_repository.dart`
- Create: `lib/data/repositories/meals/meals_repository_local.dart`
- Test: `test/data/repositories/meals_repository_local_test.dart`

- [ ] **Step 4.1: Criar interface abstract**

Create `lib/data/repositories/meals/meals_repository.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../../../domain/models/meal.dart';
import '../../../utils/result.dart';

/// SSOT do estado de refeições + meta diária.
///
/// `goalListenable` é separado para a UI que só observa a meta (sem
/// re-renderizar quando refeições mudam). `notifyListeners` dispara
/// quando a meta muda; refeições do dia chegam via stream.
abstract class MealsRepository extends ChangeNotifier {
  bool get isInitialized;

  ValueListenable<int?> get goalListenable;
  int? get currentGoal;

  /// Stream com replay-on-subscribe das refeições do [day]. Re-emite
  /// ao adicionar/atualizar/excluir.
  Stream<List<Meal>> watchMealsForDay(DateTime day);

  Future<Result<Meal>> addMeal({required String name, required int calories});
  Future<Result<Meal>> updateMeal(Meal meal);
  Future<Result<void>> deleteMeal(int id);

  /// Reinsere uma refeição que foi deletada (undo do snackbar).
  /// Retorna a Meal com o NOVO id atribuído.
  Future<Result<Meal>> reinsertMeal(Meal meal);

  Future<void> setGoal(int kcal);
  Future<void> clearGoal();
}

class MealsException implements Exception {
  const MealsException(this.message);
  final String message;
  @override
  String toString() => 'MealsException: $message';
}
```

- [ ] **Step 4.2: Escrever testes do `MealsRepositoryLocal`**

Create `test/data/repositories/meals_repository_local_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository.dart';
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
      // espera bootstrap
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
      // insere refeição "ontem"
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
```

- [ ] **Step 4.3: Rodar (deve falhar)**

```bash
flutter test test/data/repositories/meals_repository_local_test.dart
```

Esperado: erro `MealsRepositoryLocal not found`.

- [ ] **Step 4.4: Implementar `MealsRepositoryLocal`**

Create `lib/data/repositories/meals/meals_repository_local.dart`:

```dart
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
    _todayCtrl.close();
    _goal.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4.5: Rodar (deve passar)**

```bash
flutter test test/data/repositories/meals_repository_local_test.dart
```

Esperado: 9 tests pass.

- [ ] **Step 4.6: Commit**

```bash
git add lib/data/repositories/meals/ test/data/repositories/meals_repository_local_test.dart
git commit -m "feat(meals): add MealsRepository with sqflite-backed implementation"
```

---

## Task 5: `MealsViewModel`

**Files:**
- Create: `lib/ui/meals/view_models/meals_view_model.dart`
- Test: `test/ui/meals_view_model_test.dart`

- [ ] **Step 5.1: Escrever teste**

Create `test/ui/meals_view_model_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/ui/meals/view_models/meals_view_model.dart';
import 'package:mamba_growth/utils/result.dart';

class _FakeMealsRepository extends ChangeNotifier implements MealsRepository {
  bool _isInitialized = true;
  final ValueNotifier<int?> _goal = ValueNotifier<int?>(null);
  final List<Meal> _meals = [];
  int _nextId = 1;

  @override
  bool get isInitialized => _isInitialized;

  @override
  ValueListenable<int?> get goalListenable => _goal;

  @override
  int? get currentGoal => _goal.value;

  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) async* {
    yield List.unmodifiable(_meals);
  }

  @override
  Future<Result<Meal>> addMeal({
    required String name,
    required int calories,
  }) async {
    final meal = Meal(
      id: _nextId++,
      name: name,
      calories: calories,
      eatenAt: DateTime.now(),
    );
    _meals.insert(0, meal);
    notifyListeners();
    return Result.ok(meal);
  }

  @override
  Future<Result<Meal>> updateMeal(Meal meal) async {
    final i = _meals.indexWhere((m) => m.id == meal.id);
    if (i == -1) {
      return const Result.error(MealsException('not found'));
    }
    _meals[i] = meal;
    notifyListeners();
    return Result.ok(meal);
  }

  @override
  Future<Result<void>> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<Meal>> reinsertMeal(Meal meal) async {
    final restored = meal.copyWith(id: _nextId++);
    _meals.insert(0, restored);
    notifyListeners();
    return Result.ok(restored);
  }

  @override
  Future<void> setGoal(int kcal) async {
    _goal.value = kcal;
    notifyListeners();
  }

  @override
  Future<void> clearGoal() async {
    _goal.value = null;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MealsViewModel', () {
    test('expõe meta e refeições, calcula totalKcal', () async {
      final repo = _FakeMealsRepository();
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      expect(vm.totalKcal, 0);
      expect(vm.goal, isNull);
      expect(vm.overGoal, false);

      await repo.addMeal(name: 'A', calories: 300);
      await repo.addMeal(name: 'B', calories: 400);
      await Future.delayed(Duration.zero);
      expect(vm.totalKcal, 700);
    });

    test('progress = total/goal e overGoal quando excede', () async {
      final repo = _FakeMealsRepository();
      await repo.setGoal(1000);
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      await repo.addMeal(name: 'A', calories: 600);
      await Future.delayed(Duration.zero);
      expect(vm.progress, closeTo(0.6, 1e-6));
      expect(vm.overGoal, false);

      await repo.addMeal(name: 'B', calories: 600);
      await Future.delayed(Duration.zero);
      expect(vm.progress, closeTo(1.2, 1e-6));
      expect(vm.overGoal, true);
    });

    test('addMeal Command roda', () async {
      final repo = _FakeMealsRepository();
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      await vm.addMeal.execute((name: 'Café', calories: 380));
      expect(vm.addMeal.completed, true);
    });

    test('deleteMeal Command + undoDelete restaura', () async {
      final repo = _FakeMealsRepository();
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      final added = await repo.addMeal(name: 'X', calories: 100);
      final meal = (added as Ok<Meal>).value;
      await Future.delayed(Duration.zero);
      expect(vm.meals.length, 1);

      await vm.deleteMeal.execute(meal);
      await Future.delayed(Duration.zero);
      expect(vm.meals.length, 0);

      await vm.undoDelete(meal);
      await Future.delayed(Duration.zero);
      expect(vm.meals.length, 1);
    });
  });
}
```

- [ ] **Step 5.2: Rodar (deve falhar)**

```bash
flutter test test/ui/meals_view_model_test.dart
```

- [ ] **Step 5.3: Implementar `MealsViewModel`**

Create `lib/ui/meals/view_models/meals_view_model.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../domain/models/meal.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class MealsViewModel extends ChangeNotifier with WidgetsBindingObserver {
  MealsViewModel({required MealsRepository repository}) : _repo = repository {
    _repo.addListener(_onRepoChanged);
    _repo.goalListenable.addListener(_onGoalChanged);
    WidgetsBinding.instance.addObserver(this);

    addMeal = Command1<Meal, ({String name, int calories})>(
      (args) => _repo.addMeal(name: args.name, calories: args.calories),
    );
    updateMeal = Command1<Meal, Meal>(_repo.updateMeal);
    deleteMeal = Command1<void, Meal>((meal) => _repo.deleteMeal(meal.id));

    _day = _startOfDay(DateTime.now());
    _subscribe();
  }

  final MealsRepository _repo;

  late final Command1<Meal, ({String name, int calories})> addMeal;
  late final Command1<Meal, Meal> updateMeal;
  late final Command1<void, Meal> deleteMeal;

  DateTime _day = DateTime.now();
  StreamSubscription<List<Meal>>? _sub;
  List<Meal> _meals = const [];

  bool get isInitialized => _repo.isInitialized;
  DateTime get day => _day;
  List<Meal> get meals => _meals;
  int get totalKcal => _meals.fold(0, (sum, m) => sum + m.calories);
  int? get goal => _repo.currentGoal;
  double get progress {
    final g = goal;
    if (g == null || g == 0) return 0;
    return totalKcal / g;
  }

  bool get overGoal {
    final g = goal;
    return g != null && totalKcal > g;
  }

  Future<void> undoDelete(Meal meal) async {
    await _repo.reinsertMeal(meal);
  }

  DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watchMealsForDay(_day).listen((list) {
      _meals = list;
      notifyListeners();
    });
  }

  void _onRepoChanged() => notifyListeners();
  void _onGoalChanged() => notifyListeners();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _startOfDay(DateTime.now());
      if (today != _day) {
        _day = today;
        _subscribe();
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _repo.removeListener(_onRepoChanged);
    _repo.goalListenable.removeListener(_onGoalChanged);
    WidgetsBinding.instance.removeObserver(this);
    addMeal.dispose();
    updateMeal.dispose();
    deleteMeal.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 5.4: Rodar (deve passar)**

```bash
flutter test test/ui/meals_view_model_test.dart
```

- [ ] **Step 5.5: Commit**

```bash
git add lib/ui/meals/view_models/ test/ui/meals_view_model_test.dart
git commit -m "feat(meals): add MealsViewModel with totalKcal and overGoal derivations"
```

---

## Task 6: L10n PT/EN

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_pt.arb`

- [ ] **Step 6.1: Adicionar strings ao `app_pt.arb`**

Edit `lib/l10n/app_pt.arb` — adicionar (antes do `}` final):

```json
,
  "mealsTodayEyebrowWithGoal": "HOJE · META {goal} KCAL",
  "@mealsTodayEyebrowWithGoal": {
    "placeholders": { "goal": { "type": "int" } }
  },
  "mealsTodayEyebrowNoGoal": "HOJE",
  "mealsKcalUnit": "kcal",
  "mealsRemainingLabel": "{n} kcal restantes",
  "@mealsRemainingLabel": {
    "placeholders": { "n": { "type": "int" } }
  },
  "mealsOfGoalLabel": "de {goal} kcal",
  "@mealsOfGoalLabel": {
    "placeholders": { "goal": { "type": "int" } }
  },
  "mealsOverGoalLabel": "{n} kcal acima da meta",
  "@mealsOverGoalLabel": {
    "placeholders": { "n": { "type": "int" } }
  },
  "mealsAtGoalLabel": "Meta atingida",
  "mealsListEyebrowOne": "HOJE · 1 REFEIÇÃO",
  "mealsListEyebrowMany": "HOJE · {count} REFEIÇÕES",
  "@mealsListEyebrowMany": {
    "placeholders": { "count": { "type": "int" } }
  },
  "mealsAddCta": "Adicionar refeição",
  "mealsEmptyTodayTitle": "Nenhuma refeição registrada hoje.",
  "mealsEmptyTodaySubtitle": "Toque no botão abaixo para registrar sua primeira refeição do dia.",
  "mealsNoGoalHint": "Defina uma meta no perfil para acompanhar seu progresso",
  "mealSheetNewTitle": "Nova refeição",
  "mealSheetEditTitle": "Editar refeição",
  "mealSheetTimeLabel": "Hoje · {time}",
  "@mealSheetTimeLabel": {
    "placeholders": { "time": { "type": "String" } }
  },
  "mealSheetNameLabel": "Nome",
  "mealSheetNameHint": "Café da manhã",
  "mealSheetCaloriesLabel": "Calorias",
  "mealSheetSave": "Salvar",
  "mealSheetSaveEdit": "Salvar alterações",
  "mealSheetCancel": "Cancelar",
  "mealItemMenuEdit": "Editar",
  "mealItemMenuDelete": "Excluir",
  "mealDeleteDialogTitle": "Excluir refeição?",
  "mealDeleteDialogBody": "Você pode desfazer logo após excluir.",
  "mealDeleteDialogConfirm": "Excluir",
  "mealDeleteDialogCancel": "Cancelar",
  "mealDeletedSnackbar": "Refeição removida",
  "mealDeletedSnackbarUndo": "Desfazer",
  "mealAddedSnackbar": "Refeição adicionada",
  "mealValidationNameRequired": "Informe o nome",
  "mealValidationNameTooLong": "Máximo 60 caracteres",
  "mealValidationCaloriesRequired": "Informe as calorias",
  "mealValidationCaloriesRange": "Entre 1 e 9999",
  "mealItemA11y": "{name}, {calories} kcal, registrado às {time}. Toque para editar.",
  "@mealItemA11y": {
    "placeholders": {
      "name": { "type": "String" },
      "calories": { "type": "int" },
      "time": { "type": "String" }
    }
  },
  "mealsRingA11yWithGoal": "{consumed} kcal de {goal}. {remaining} restantes.",
  "@mealsRingA11yWithGoal": {
    "placeholders": {
      "consumed": { "type": "int" },
      "goal": { "type": "int" },
      "remaining": { "type": "int" }
    }
  },
  "mealsRingA11yOverGoal": "{consumed} kcal. {over} acima da meta de {goal}.",
  "@mealsRingA11yOverGoal": {
    "placeholders": {
      "consumed": { "type": "int" },
      "over": { "type": "int" },
      "goal": { "type": "int" }
    }
  },
  "mealsRingA11yNoGoal": "{consumed} kcal hoje.",
  "@mealsRingA11yNoGoal": {
    "placeholders": { "consumed": { "type": "int" } }
  },
  "profileGoalSectionEyebrow": "CALORIAS",
  "profileGoalCardTitle": "Meta diária",
  "profileGoalCardValue": "{kcal} kcal por dia",
  "@profileGoalCardValue": {
    "placeholders": { "kcal": { "type": "int" } }
  },
  "profileGoalCardEmptyValue": "Acompanhe seu progresso diário",
  "profileGoalCardActionDefine": "Definir",
  "profileGoalCardActionEdit": "Editar",
  "profileGoalSheetTitle": "Meta diária",
  "profileGoalSheetSubtitle": "Quantas calorias você quer consumir por dia?",
  "profileGoalSheetSuggestionsLabel": "Sugestões",
  "profileGoalSheetSave": "Salvar",
  "profileGoalSheetRemove": "Remover meta",
  "profileGoalValidationRange": "Entre 500 e 9999"
```

- [ ] **Step 6.2: Adicionar strings ao `app_en.arb`**

Edit `lib/l10n/app_en.arb` — adicionar (antes do `}` final), versão EN das mesmas chaves:

```json
,
  "mealsTodayEyebrowWithGoal": "TODAY · GOAL {goal} KCAL",
  "@mealsTodayEyebrowWithGoal": { "placeholders": { "goal": { "type": "int" } } },
  "mealsTodayEyebrowNoGoal": "TODAY",
  "mealsKcalUnit": "kcal",
  "mealsRemainingLabel": "{n} kcal remaining",
  "@mealsRemainingLabel": { "placeholders": { "n": { "type": "int" } } },
  "mealsOfGoalLabel": "of {goal} kcal",
  "@mealsOfGoalLabel": { "placeholders": { "goal": { "type": "int" } } },
  "mealsOverGoalLabel": "{n} kcal over goal",
  "@mealsOverGoalLabel": { "placeholders": { "n": { "type": "int" } } },
  "mealsAtGoalLabel": "Goal reached",
  "mealsListEyebrowOne": "TODAY · 1 MEAL",
  "mealsListEyebrowMany": "TODAY · {count} MEALS",
  "@mealsListEyebrowMany": { "placeholders": { "count": { "type": "int" } } },
  "mealsAddCta": "Add meal",
  "mealsEmptyTodayTitle": "No meals logged today.",
  "mealsEmptyTodaySubtitle": "Tap the button below to log your first meal of the day.",
  "mealsNoGoalHint": "Set a goal in your profile to track progress",
  "mealSheetNewTitle": "New meal",
  "mealSheetEditTitle": "Edit meal",
  "mealSheetTimeLabel": "Today · {time}",
  "@mealSheetTimeLabel": { "placeholders": { "time": { "type": "String" } } },
  "mealSheetNameLabel": "Name",
  "mealSheetNameHint": "Breakfast",
  "mealSheetCaloriesLabel": "Calories",
  "mealSheetSave": "Save",
  "mealSheetSaveEdit": "Save changes",
  "mealSheetCancel": "Cancel",
  "mealItemMenuEdit": "Edit",
  "mealItemMenuDelete": "Delete",
  "mealDeleteDialogTitle": "Delete meal?",
  "mealDeleteDialogBody": "You can undo right after deleting.",
  "mealDeleteDialogConfirm": "Delete",
  "mealDeleteDialogCancel": "Cancel",
  "mealDeletedSnackbar": "Meal removed",
  "mealDeletedSnackbarUndo": "Undo",
  "mealAddedSnackbar": "Meal added",
  "mealValidationNameRequired": "Enter a name",
  "mealValidationNameTooLong": "Max 60 characters",
  "mealValidationCaloriesRequired": "Enter calories",
  "mealValidationCaloriesRange": "Between 1 and 9999",
  "mealItemA11y": "{name}, {calories} kcal, logged at {time}. Tap to edit.",
  "@mealItemA11y": {
    "placeholders": {
      "name": { "type": "String" },
      "calories": { "type": "int" },
      "time": { "type": "String" }
    }
  },
  "mealsRingA11yWithGoal": "{consumed} kcal of {goal}. {remaining} remaining.",
  "@mealsRingA11yWithGoal": {
    "placeholders": {
      "consumed": { "type": "int" },
      "goal": { "type": "int" },
      "remaining": { "type": "int" }
    }
  },
  "mealsRingA11yOverGoal": "{consumed} kcal. {over} over goal of {goal}.",
  "@mealsRingA11yOverGoal": {
    "placeholders": {
      "consumed": { "type": "int" },
      "over": { "type": "int" },
      "goal": { "type": "int" }
    }
  },
  "mealsRingA11yNoGoal": "{consumed} kcal today.",
  "@mealsRingA11yNoGoal": {
    "placeholders": { "consumed": { "type": "int" } }
  },
  "profileGoalSectionEyebrow": "CALORIES",
  "profileGoalCardTitle": "Daily goal",
  "profileGoalCardValue": "{kcal} kcal per day",
  "@profileGoalCardValue": { "placeholders": { "kcal": { "type": "int" } } },
  "profileGoalCardEmptyValue": "Track your daily progress",
  "profileGoalCardActionDefine": "Set",
  "profileGoalCardActionEdit": "Edit",
  "profileGoalSheetTitle": "Daily goal",
  "profileGoalSheetSubtitle": "How many calories do you want to consume per day?",
  "profileGoalSheetSuggestionsLabel": "Suggestions",
  "profileGoalSheetSave": "Save",
  "profileGoalSheetRemove": "Remove goal",
  "profileGoalValidationRange": "Between 500 and 9999"
```

- [ ] **Step 6.3: Regenerar arquivos**

```bash
flutter gen-l10n
```

Esperado: regenera `lib/l10n/generated/app_localizations*.dart` sem erros.

- [ ] **Step 6.4: Análise**

```bash
flutter analyze
```

Esperado: `No issues found!`.

- [ ] **Step 6.5: Commit**

```bash
git add lib/l10n/app_pt.arb lib/l10n/app_en.arb lib/l10n/generated/
git commit -m "feat(l10n): add strings for meals feature (PT + EN)"
```

---

## Task 7: `MealListItem` widget

**Files:**
- Create: `lib/ui/meals/widgets/meal_list_item.dart`

(Sem teste isolado — coberto pelos widget tests do screen na Task 9.)

- [ ] **Step 7.1: Implementar**

Create `lib/ui/meals/widgets/meal_list_item.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class MealListItem extends StatelessWidget {
  const MealListItem({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeStr = DateFormat.Hm(locale).format(meal.eatenAt);

    return Semantics(
      button: true,
      label: l10n.mealItemA11y(meal.name, meal.calories, timeStr),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.borderDim),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: text.titleMedium?.copyWith(color: colors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meal.calories} ${l10n.mealsKcalUnit}',
                        style: typo.numericMedium.copyWith(color: colors.text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  timeStr,
                  style: typo.numericSmall.copyWith(color: colors.textDim),
                ),
                const SizedBox(width: AppSpacing.xs),
                _MoreButton(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<_MealAction>(
      icon: Icon(Icons.more_vert_rounded, color: colors.textDim, size: 20),
      tooltip: '',
      color: colors.surface2,
      onSelected: (action) {
        switch (action) {
          case _MealAction.edit:
            onEdit();
          case _MealAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MealAction.edit,
          child: Text(
            l10n.mealItemMenuEdit,
            style: text.bodyMedium?.copyWith(color: colors.text),
          ),
        ),
        PopupMenuItem(
          value: _MealAction.delete,
          child: Text(
            l10n.mealItemMenuDelete,
            style: text.bodyMedium?.copyWith(color: const Color(0xFFE76D6D)),
          ),
        ),
      ],
    );
  }
}

enum _MealAction { edit, delete }
```

- [ ] **Step 7.2: Análise**

```bash
flutter analyze
```

Esperado: clean.

- [ ] **Step 7.3: Commit**

```bash
git add lib/ui/meals/widgets/meal_list_item.dart
git commit -m "feat(meals): add MealListItem card with edit/delete menu"
```

---

## Task 8: `AddMealSheet`

**Files:**
- Create: `lib/ui/meals/widgets/add_meal_sheet.dart`
- Test: `test/ui/add_meal_sheet_test.dart`

- [ ] **Step 8.1: Escrever teste**

Create `test/ui/add_meal_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/ui/core/themes/app_theme.dart';
import 'package:mamba_growth/ui/meals/widgets/add_meal_sheet.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  Meal? initial,
  Future<void> Function(String, int)? onSave,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt'), Locale('en')],
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => AddMealSheet.show(
                context,
                initial: initial,
                onSave: onSave ?? (_, _) async {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Save desabilitado quando inputs inválidos', (tester) async {
    await _pumpSheet(tester);
    final saveBtn = find.widgetWithText(FilledButton, 'Save');
    expect(saveBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);
  });

  testWidgets('Save chama onSave com valores corretos', (tester) async {
    String? gotName;
    int? gotCalories;
    await _pumpSheet(
      tester,
      onSave: (n, c) async {
        gotName = n;
        gotCalories = c;
      },
    );

    await tester.enterText(find.bySemanticsLabel('Name'), 'Almoço');
    await tester.enterText(find.bySemanticsLabel('Calories'), '620');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(gotName, 'Almoço');
    expect(gotCalories, 620);
  });

  testWidgets('Modo edição pré-preenche e usa "Save changes"', (tester) async {
    await _pumpSheet(
      tester,
      initial: Meal(
        id: 1,
        name: 'Existente',
        calories: 300,
        eatenAt: DateTime(2026, 4, 29, 12, 0),
      ),
    );
    expect(find.text('Existente'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
  });
}
```

- [ ] **Step 8.2: Rodar (deve falhar)**

```bash
flutter test test/ui/add_meal_sheet_test.dart
```

- [ ] **Step 8.3: Implementar `AddMealSheet`**

Create `lib/ui/meals/widgets/add_meal_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({
    super.key,
    required this.onSave,
    this.initial,
  });

  final Meal? initial;
  final Future<void> Function(String name, int calories) onSave;

  static Future<void> show(
    BuildContext context, {
    Meal? initial,
    required Future<void> Function(String name, int calories) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMealSheet(initial: initial, onSave: onSave),
    );
  }

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  late final TextEditingController _name;
  late final TextEditingController _cal;
  late final FocusNode _nameFocus;
  late final FocusNode _calFocus;
  late final DateTime _frozenNow;
  String? _nameError;
  String? _calError;
  bool _saving = false;

  static const _maxName = 60;
  static const _maxCal = 9999;

  @override
  void initState() {
    super.initState();
    _frozenNow = widget.initial?.eatenAt ?? DateTime.now();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _cal = TextEditingController(
      text: widget.initial != null ? widget.initial!.calories.toString() : '',
    );
    _nameFocus = FocusNode()..addListener(_onNameBlur);
    _calFocus = FocusNode()..addListener(_onCalBlur);
    _name.addListener(_revalidateOnChange);
    _cal.addListener(_revalidateOnChange);
  }

  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    _nameFocus.dispose();
    _calFocus.dispose();
    super.dispose();
  }

  void _onNameBlur() {
    if (!_nameFocus.hasFocus) {
      setState(() => _nameError = _validateName(_name.text));
    }
  }

  void _onCalBlur() {
    if (!_calFocus.hasFocus) {
      setState(() => _calError = _validateCalories(_cal.text));
    }
  }

  void _revalidateOnChange() {
    // Limpa erro à medida que o usuário corrige; não reapresenta sem blur.
    if (_nameError != null && _validateName(_name.text) == null) {
      setState(() => _nameError = null);
    }
    if (_calError != null && _validateCalories(_cal.text) == null) {
      setState(() => _calError = null);
    }
    setState(() {}); // habilita/desabilita Save
  }

  String? _validateName(String s) {
    final l10n = AppLocalizations.of(context);
    final t = s.trim();
    if (t.isEmpty) return l10n.mealValidationNameRequired;
    if (t.length > _maxName) return l10n.mealValidationNameTooLong;
    return null;
  }

  String? _validateCalories(String s) {
    final l10n = AppLocalizations.of(context);
    if (s.trim().isEmpty) return l10n.mealValidationCaloriesRequired;
    final v = int.tryParse(s.trim());
    if (v == null || v < 1 || v > _maxCal) {
      return l10n.mealValidationCaloriesRange;
    }
    return null;
  }

  bool get _isValid =>
      _validateName(_name.text) == null &&
      _validateCalories(_cal.text) == null;

  Future<void> _submit() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      await widget.onSave(_name.text.trim(), int.parse(_cal.text.trim()));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.initial != null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeStr = DateFormat.Hm(locale).format(_frozenNow);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isEdit ? l10n.mealSheetEditTitle : l10n.mealSheetNewTitle,
              style: text.headlineSmall?.copyWith(color: colors.text),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mealSheetTimeLabel(timeStr),
              style: text.bodyMedium?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label(text: l10n.mealSheetNameLabel),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _name,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              maxLength: _maxName,
              decoration: InputDecoration(
                hintText: l10n.mealSheetNameHint,
                errorText: _nameError,
                filled: true,
                fillColor: colors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _calFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            _Label(text: l10n.mealSheetCaloriesLabel),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _cal,
              focusNode: _calFocus,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: typo.numericLarge.copyWith(color: colors.text),
              decoration: InputDecoration(
                suffixText: l10n.mealsKcalUnit,
                errorText: _calError,
                filled: true,
                fillColor: colors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isValid && !_saving ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(colors.bg),
                        ),
                      )
                    : Text(
                        isEdit ? l10n.mealSheetSaveEdit : l10n.mealSheetSave,
                        style: text.labelLarge?.copyWith(
                          color: colors.bg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(
                  l10n.mealSheetCancel,
                  style: text.labelLarge?.copyWith(color: colors.textDim),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final txt = context.text;
    return Text(
      text,
      style: txt.labelMedium?.copyWith(color: colors.textDim),
    );
  }
}
```

- [ ] **Step 8.4: Rodar (deve passar)**

```bash
flutter test test/ui/add_meal_sheet_test.dart
```

- [ ] **Step 8.5: Commit**

```bash
git add lib/ui/meals/widgets/add_meal_sheet.dart test/ui/add_meal_sheet_test.dart
git commit -m "feat(meals): add AddMealSheet modal with validation"
```

---

## Task 9: `MealsScreen` (com provider scoped)

**Files:**
- Modify: `lib/ui/meals/widgets/meals_screen.dart`
- Test: `test/ui/meals_screen_test.dart`

- [ ] **Step 9.1: Escrever teste**

Create `test/ui/meals_screen_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/ui/core/themes/app_theme.dart';
import 'package:mamba_growth/ui/meals/widgets/meals_screen.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:provider/provider.dart';

class _FakeMealsRepository extends ChangeNotifier implements MealsRepository {
  final ValueNotifier<int?> _goal = ValueNotifier<int?>(null);
  final List<Meal> _meals = [];

  void seedMeals(List<Meal> list) {
    _meals
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void setInitialGoal(int? g) => _goal.value = g;

  @override
  bool get isInitialized => true;

  @override
  ValueListenable<int?> get goalListenable => _goal;

  @override
  int? get currentGoal => _goal.value;

  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) async* {
    yield List.unmodifiable(_meals);
  }

  @override
  Future<Result<Meal>> addMeal({
    required String name,
    required int calories,
  }) async {
    final m = Meal(
      id: _meals.length + 1,
      name: name,
      calories: calories,
      eatenAt: DateTime.now(),
    );
    _meals.insert(0, m);
    notifyListeners();
    return Result.ok(m);
  }

  @override
  Future<Result<Meal>> updateMeal(Meal meal) async => Result.ok(meal);

  @override
  Future<Result<void>> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<Meal>> reinsertMeal(Meal meal) async {
    _meals.insert(0, meal);
    notifyListeners();
    return Result.ok(meal);
  }

  @override
  Future<void> setGoal(int kcal) async {
    _goal.value = kcal;
    notifyListeners();
  }

  @override
  Future<void> clearGoal() async {
    _goal.value = null;
    notifyListeners();
  }
}

Widget _wrap(Widget child, _FakeMealsRepository repo) {
  return MaterialApp(
    theme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('pt'), Locale('en')],
    locale: const Locale('en'),
    home: ChangeNotifierProvider<MealsRepository>.value(
      value: repo,
      child: child,
    ),
  );
}

void main() {
  testWidgets('mostra empty state quando sem refeições e com meta',
      (tester) async {
    final repo = _FakeMealsRepository()..setInitialGoal(2000);
    await tester.pumpWidget(_wrap(const MealsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('No meals logged today.'), findsOneWidget);
    expect(find.text('Add meal'), findsOneWidget);
  });

  testWidgets('mostra lista de refeições e total', (tester) async {
    final repo = _FakeMealsRepository()
      ..setInitialGoal(2000)
      ..seedMeals([
        Meal(
          id: 1,
          name: 'Almoço',
          calories: 620,
          eatenAt: DateTime(2026, 4, 29, 12, 30),
        ),
      ]);
    await tester.pumpWidget(_wrap(const MealsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('620 kcal'), findsOneWidget);
  });

  testWidgets('com meta excedida mostra label de overflow', (tester) async {
    final repo = _FakeMealsRepository()
      ..setInitialGoal(500)
      ..seedMeals([
        Meal(
          id: 1,
          name: 'X',
          calories: 800,
          eatenAt: DateTime.now(),
        ),
      ]);
    await tester.pumpWidget(_wrap(const MealsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('over goal'), findsOneWidget);
  });

  testWidgets('sem meta mostra hint de definir', (tester) async {
    final repo = _FakeMealsRepository();
    await tester.pumpWidget(_wrap(const MealsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Set a goal'), findsOneWidget);
  });
}
```

- [ ] **Step 9.2: Rodar (deve falhar)**

```bash
flutter test test/ui/meals_screen_test.dart
```

- [ ] **Step 9.3: Implementar `MealsScreen`**

Edit `lib/ui/meals/widgets/meals_screen.dart` — substituir conteúdo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';
import '../../core/widgets/progress_ring.dart';
import '../view_models/meals_view_model.dart';
import 'add_meal_sheet.dart';
import 'meal_list_item.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MealsViewModel>(
      create: (ctx) => MealsViewModel(repository: ctx.read<MealsRepository>()),
      child: const _MealsView(),
    );
  }
}

class _MealsView extends StatelessWidget {
  const _MealsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navMeals)),
      body: SafeArea(
        top: false,
        child: Consumer<MealsViewModel>(
          builder: (context, vm, _) {
            if (!vm.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Body(vm: vm);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});
  final MealsViewModel vm;

  Future<void> _openAdd(BuildContext context) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await AddMealSheet.show(
      context,
      onSave: (name, calories) async {
        await vm.addMeal.execute((name: name, calories: calories));
        if (vm.addMeal.completed) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.mealAddedSnackbar)),
          );
        }
      },
    );
  }

  Future<void> _openEdit(BuildContext context, Meal meal) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await AddMealSheet.show(
      context,
      initial: meal,
      onSave: (name, calories) async {
        await vm.updateMeal.execute(
          meal.copyWith(name: name, calories: calories),
        );
        if (vm.updateMeal.completed) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.mealAddedSnackbar)),
          );
        }
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Meal meal) async {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(l10n.mealDeleteDialogTitle),
        content: Text(l10n.mealDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.mealDeleteDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.mealDeleteDialogConfirm,
              style: const TextStyle(color: Color(0xFFE76D6D)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await vm.deleteMeal.execute(meal);
    if (vm.deleteMeal.completed) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mealDeletedSnackbar),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l10n.mealDeletedSnackbarUndo,
              onPressed: () => vm.undoDelete(meal),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;

    final hasGoal = vm.goal != null;
    final eyebrow = hasGoal
        ? l10n.mealsTodayEyebrowWithGoal(vm.goal!)
        : l10n.mealsTodayEyebrowNoGoal;
    final ringSize =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            eyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: hasGoal
                ? _RingHero(vm: vm, size: ringSize)
                : _NumberHero(vm: vm),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Subtitle(vm: vm),
          const SizedBox(height: AppSpacing.xl),
          Divider(color: colors.borderDim, height: 1),
          const SizedBox(height: AppSpacing.lg),
          if (vm.meals.isEmpty)
            EmptyFeatureState(
              icon: Icons.restaurant_outlined,
              title: l10n.mealsEmptyTodayTitle,
              subtitle: l10n.mealsEmptyTodaySubtitle,
            )
          else ...[
            Text(
              vm.meals.length == 1
                  ? l10n.mealsListEyebrowOne
                  : l10n.mealsListEyebrowMany(vm.meals.length),
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final meal in vm.meals) ...[
              MealListItem(
                meal: meal,
                onTap: () => _openEdit(context, meal),
                onEdit: () => _openEdit(context, meal),
                onDelete: () => _confirmDelete(context, meal),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _openAdd(context),
              icon: Icon(Icons.add_rounded, color: colors.bg),
              label: Text(
                l10n.mealsAddCta,
                style: text.labelLarge?.copyWith(
                  color: colors.bg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _RingHero extends StatelessWidget {
  const _RingHero({required this.vm, required this.size});
  final MealsViewModel vm;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final ringColor = vm.overGoal ? colors.accentWarm : colors.accent;
    final remaining = (vm.goal ?? 0) - vm.totalKcal;
    final over = vm.totalKcal - (vm.goal ?? 0);
    final label = vm.overGoal
        ? l10n.mealsRingA11yOverGoal(vm.totalKcal, over, vm.goal!)
        : l10n.mealsRingA11yWithGoal(
            vm.totalKcal,
            vm.goal!,
            remaining < 0 ? 0 : remaining,
          );

    return Semantics(
      label: label,
      child: ProgressRing(
        progress: vm.progress,
        size: size,
        color: ringColor,
        overflowColor: colors.accentWarm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.totalKcal.toString(),
              style: typo.numericLarge.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.mealsKcalUnit,
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberHero extends StatelessWidget {
  const _NumberHero({required this.vm});
  final MealsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.mealsRingA11yNoGoal(vm.totalKcal),
      child: Column(
        children: [
          Text(
            vm.totalKcal.toString(),
            style: typo.numericDisplay.copyWith(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.mealsKcalUnit,
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.vm});
  final MealsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    if (vm.goal == null) {
      return InkWell(
        onTap: () => Navigator.of(context).pushNamed(Routes.profile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            l10n.mealsNoGoalHint,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ),
      );
    }

    if (vm.overGoal) {
      final over = vm.totalKcal - vm.goal!;
      return Column(
        children: [
          Text(
            l10n.mealsOverGoalLabel(over),
            style: text.bodyLarge?.copyWith(
              color: colors.accentWarm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.mealsOfGoalLabel(vm.goal!),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ],
      );
    }

    final remaining = vm.goal! - vm.totalKcal;
    return Column(
      children: [
        Text(
          remaining > 0
              ? l10n.mealsRemainingLabel(remaining)
              : l10n.mealsAtGoalLabel,
          style: text.bodyLarge?.copyWith(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.mealsOfGoalLabel(vm.goal!),
          style: text.bodyMedium?.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}
```

- [ ] **Step 9.4: Rodar testes do screen**

```bash
flutter test test/ui/meals_screen_test.dart
```

- [ ] **Step 9.5: Rodar suíte completa**

```bash
flutter analyze && flutter test
```

- [ ] **Step 9.6: Commit**

```bash
git add lib/ui/meals/widgets/meals_screen.dart test/ui/meals_screen_test.dart
git commit -m "feat(meals): implement MealsScreen with ring, list, and add CTA"
```

---

## Task 10: Wire-up no `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 10.1: Registrar `MealsRepositoryLocal` no MultiProvider**

Edit `lib/main.dart`:

Adicionar imports (após os existentes do data/repositories):

```dart
import 'data/repositories/meals/meals_repository.dart';
import 'data/repositories/meals/meals_repository_local.dart';
```

Antes de `runApp(...)`, criar instância:

```dart
final mealsRepository = MealsRepositoryLocal(database: localDatabase);
```

Passar para `MambaGrowthApp`:

```dart
runApp(MambaGrowthApp(
  authRepository: authRepository,
  fastingRepository: fastingRepository,
  mealsRepository: mealsRepository,
  notificationService: notificationService,
  localDatabase: localDatabase,
));
```

Em `MambaGrowthApp` adicionar campo `final MealsRepository mealsRepository;` e no construtor.

No `MultiProvider`, adicionar:

```dart
ChangeNotifierProvider<MealsRepository>.value(value: mealsRepository),
```

- [ ] **Step 10.2: Rodar análise + testes**

```bash
flutter analyze && flutter test
```

Esperado: clean.

- [ ] **Step 10.3: Smoke run no device/simulator (manual)**

```bash
flutter run
```

Verificar que o app abre, a aba Refeições agora mostra a tela nova com empty state, e que o app não crasheu na inicialização.

- [ ] **Step 10.4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(meals): register MealsRepository in app composition root"
```

---

## Task 11: `CalorieGoalSheet` (no Perfil)

**Files:**
- Create: `lib/ui/profile/widgets/calorie_goal_sheet.dart`
- Test: `test/ui/calorie_goal_sheet_test.dart`

- [ ] **Step 11.1: Escrever teste**

Create `test/ui/calorie_goal_sheet_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/ui/core/themes/app_theme.dart';
import 'package:mamba_growth/ui/profile/widgets/calorie_goal_sheet.dart';
import 'package:mamba_growth/utils/result.dart';
import 'package:provider/provider.dart';

class _Repo extends ChangeNotifier implements MealsRepository {
  final ValueNotifier<int?> _goal = ValueNotifier<int?>(null);

  @override
  bool get isInitialized => true;
  @override
  ValueListenable<int?> get goalListenable => _goal;
  @override
  int? get currentGoal => _goal.value;
  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) async* { yield []; }
  @override
  Future<Result<Meal>> addMeal({required String name, required int calories}) async =>
      const Result.error(MealsException('na'));
  @override
  Future<Result<Meal>> updateMeal(Meal m) async => Result.ok(m);
  @override
  Future<Result<void>> deleteMeal(int id) async => const Result.ok(null);
  @override
  Future<Result<Meal>> reinsertMeal(Meal m) async => Result.ok(m);
  @override
  Future<void> setGoal(int kcal) async {
    _goal.value = kcal;
    notifyListeners();
  }
  @override
  Future<void> clearGoal() async {
    _goal.value = null;
    notifyListeners();
  }
}

Future<void> _open(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt'), Locale('en')],
      locale: const Locale('en'),
      home: ChangeNotifierProvider<MealsRepository>.value(
        value: repo,
        child: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => CalorieGoalSheet.show(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Save chama setGoal', (tester) async {
    final repo = _Repo();
    await _open(tester, repo);
    await tester.enterText(find.bySemanticsLabel('Calories'), '2000');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repo.currentGoal, 2000);
  });

  testWidgets('Validação 500..9999', (tester) async {
    final repo = _Repo();
    await _open(tester, repo);
    await tester.enterText(find.bySemanticsLabel('Calories'), '100');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(find.text('Between 500 and 9999'), findsOneWidget);
  });

  testWidgets('Remover meta só aparece se já existe meta', (tester) async {
    final repo = _Repo();
    await repo.setGoal(2000);
    await _open(tester, repo);
    expect(find.widgetWithText(TextButton, 'Remove goal'), findsOneWidget);
  });
}
```

- [ ] **Step 11.2: Rodar (deve falhar)**

```bash
flutter test test/ui/calorie_goal_sheet_test.dart
```

- [ ] **Step 11.3: Implementar `CalorieGoalSheet`**

Create `lib/ui/profile/widgets/calorie_goal_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class CalorieGoalSheet extends StatefulWidget {
  const CalorieGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<MealsRepository>.value(
        value: context.read<MealsRepository>(),
        child: const CalorieGoalSheet(),
      ),
    );
  }

  @override
  State<CalorieGoalSheet> createState() => _CalorieGoalSheetState();
}

class _CalorieGoalSheetState extends State<CalorieGoalSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  static const _suggestions = [1500, 2000, 2500];
  static const _min = 500;
  static const _max = 9999;

  @override
  void initState() {
    super.initState();
    final initial = context.read<MealsRepository>().currentGoal;
    _ctrl = TextEditingController(text: initial?.toString() ?? '');
    _ctrl.addListener(() {
      if (_error != null && _validate(_ctrl.text) == null) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String s) {
    final l10n = AppLocalizations.of(context);
    final v = int.tryParse(s.trim());
    if (v == null || v < _min || v > _max) {
      return l10n.profileGoalValidationRange;
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    HapticFeedback.lightImpact();
    await context.read<MealsRepository>().setGoal(int.parse(_ctrl.text.trim()));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    HapticFeedback.lightImpact();
    await context.read<MealsRepository>().clearGoal();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final hasGoal = context.watch<MealsRepository>().currentGoal != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.profileGoalSheetTitle,
              style: text.headlineSmall?.copyWith(color: colors.text),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.profileGoalSheetSubtitle,
              style: text.bodyMedium?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: typo.numericLarge.copyWith(color: colors.text),
              decoration: InputDecoration(
                labelText: l10n.mealSheetCaloriesLabel,
                suffixText: l10n.mealsKcalUnit,
                errorText: _error,
                filled: true,
                fillColor: colors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.profileGoalSheetSuggestionsLabel.toUpperCase(),
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text('$s kcal'),
                    onPressed: () => _ctrl.text = s.toString(),
                    backgroundColor: colors.surface2,
                    side: BorderSide(color: colors.border),
                    labelStyle: text.bodyMedium?.copyWith(color: colors.text),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  l10n.profileGoalSheetSave,
                  style: text.labelLarge?.copyWith(
                    color: colors.bg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (hasGoal) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: _remove,
                  child: Text(
                    l10n.profileGoalSheetRemove,
                    style: text.labelLarge?.copyWith(color: colors.textDim),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 11.4: Rodar (deve passar)**

```bash
flutter test test/ui/calorie_goal_sheet_test.dart
```

- [ ] **Step 11.5: Commit**

```bash
git add lib/ui/profile/widgets/calorie_goal_sheet.dart test/ui/calorie_goal_sheet_test.dart
git commit -m "feat(profile): add CalorieGoalSheet for daily goal management"
```

---

## Task 12: Seção "Calorias" no Perfil

**Files:**
- Modify: `lib/ui/profile/widgets/profile_screen.dart`

(Cobertura via smoke test do screen — opcional. Foco no comportamento principal.)

- [ ] **Step 12.1: Atualizar `ProfileScreen`**

Edit `lib/ui/profile/widgets/profile_screen.dart` — substituir conteúdo:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/meals/meals_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import 'calorie_goal_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final repo = context.read<AuthRepository>();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                children: const [
                  _CalorieGoalSection(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl2,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => repo.signOut(),
                  child: Text(l10n.profileSignOut),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieGoalSection extends StatelessWidget {
  const _CalorieGoalSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final goal = context.watch<MealsRepository>().currentGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.profileGoalSectionEyebrow,
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => CalorieGoalSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderDim),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileGoalCardTitle,
                          style:
                              text.titleMedium?.copyWith(color: colors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal != null
                              ? l10n.profileGoalCardValue(goal)
                              : l10n.profileGoalCardEmptyValue,
                          style: text.bodyMedium
                              ?.copyWith(color: colors.textDim),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    goal != null
                        ? l10n.profileGoalCardActionEdit
                        : l10n.profileGoalCardActionDefine,
                    style: text.labelMedium?.copyWith(color: colors.accent),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: colors.textDim),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 12.2: Rodar análise + suíte**

```bash
flutter analyze && flutter test
```

- [ ] **Step 12.3: Commit**

```bash
git add lib/ui/profile/widgets/profile_screen.dart
git commit -m "feat(profile): add calorie goal section"
```

---

## Task 13: QA manual

- [ ] **Step 13.1: `flutter run` no device**

Roteiro:
1. Aba Refeições: vê empty state + hint "Set a goal in your profile" (sem meta).
2. Vai pro Perfil → toca no card "Daily goal" → seta `2000` → salva.
3. Volta pra Refeições: anel mostra `0` no centro, "2000 kcal remaining" abaixo.
4. Toca "Add meal" → digita "Almoço", `620` → salva. Snackbar aparece. Lista mostra item, total `620`.
5. Adiciona mais 2 refeições até passar `2000`. Anel transiciona para âmbar e o subtitle vira "X kcal over goal".
6. Toca em uma refeição → sheet de edição abre pré-preenchido. Edita pra `100` → salva. Total atualiza.
7. Toca no `⋮` → "Delete" → confirma → snackbar "Meal removed · UNDO". Toca UNDO → refeição volta.
8. Vai pro Perfil → "Remove goal" → confirma. Volta: anel some, hero numérico aparece.
9. Mata o app → reabre → meta e refeições continuam.

- [ ] **Step 13.2: Smoke em locale `pt`**

Trocar locale do device pra português, repetir item 1 e 4 acima — strings devem aparecer em PT.

- [ ] **Step 13.3: Smoke a11y**

Ligar TalkBack/VoiceOver e navegar pela tela de Refeições — labels semânticos do anel e dos cards devem ser anunciados.

- [ ] **Step 13.4: Commit final (se houver tweaks)**

```bash
git status
git diff
# se houver pequenos ajustes:
git add -p
git commit -m "polish(meals): adjustments after QA"
```

---

## Self-review (cobertura da spec)

- ✅ §1 Decisões de produto: meta opcional (Task 11/12), horário automático (Task 4 `addMeal`), só hoje (Task 5 ViewModel filtra), âmbar overflow (Task 1 + Task 9 `_RingHero`).
- ✅ §Arquitetura: refator FastingRing→ProgressRing (Task 1), camadas conforme spec (Tasks 2-5, 7-12).
- ✅ §Modelo de dados: `Meal` (Task 2), schema `meals` + migration (Task 3), `daily_calorie_goal` em `settings` (Task 4 `setGoal`).
- ✅ §Repositório: contrato (Task 4.1), implementação (Task 4.4) com cache + broadcast.
- ✅ §ViewModel: derivações `totalKcal`/`progress`/`overGoal` (Task 5), day-rollover via `WidgetsBindingObserver` (Task 5).
- ✅ §UI: `MealsScreen` (Task 9), `MealListItem` (Task 7), `AddMealSheet` (Task 8), `CalorieGoalSheet` (Task 11), seção Perfil (Task 12).
- ✅ §Estados: empty (Task 9), sem meta (Task 9 `_NumberHero`), acima da meta (Task 9 `_RingHero` + `_Subtitle`).
- ✅ §L10n PT/EN (Task 6).
- ✅ §Acessibilidade: Semantics no anel + lista (Task 7, Task 9), keyboard semântico (Tasks 8, 11), haptic (Tasks 8, 11).
- ✅ §Testes: domain (Task 2), repo (Task 4), VM (Task 5), screen (Task 9), sheets (Tasks 8, 11), DB (Task 3).

Sem placeholders. Tipos consistentes (`Meal`, `Command1<T,A>`, `MealsRepository`). Pronto para execução.
