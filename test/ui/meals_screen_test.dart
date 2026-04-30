import 'dart:async';

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
  final StreamController<List<Meal>> _ctrl =
      StreamController<List<Meal>>.broadcast();

  void seedMeals(List<Meal> list) {
    _meals
      ..clear()
      ..addAll(list);
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_meals));
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
    yield* _ctrl.stream;
  }

  @override
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end) async {
    return _meals
        .where((m) =>
            !m.eatenAt.isBefore(start) && m.eatenAt.isBefore(end))
        .toList();
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
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_meals));
    return Result.ok(m);
  }

  @override
  Future<Result<Meal>> updateMeal(Meal meal) async => Result.ok(meal);

  @override
  Future<Result<void>> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_meals));
    return const Result.ok(null);
  }

  @override
  Future<Result<Meal>> reinsertMeal(Meal meal) async {
    _meals.insert(0, meal);
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_meals));
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

  @override
  void dispose() {
    _ctrl.close();
    _goal.dispose();
    super.dispose();
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
  // Helper: ProgressRing roda uma fase animada infinita quando progress > 0,
  // então pumpAndSettle nunca retorna. Usamos pump() discreto pra deixar o
  // stream do repo flushar e a UI renderizar sem esperar a animação.
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('mostra empty state quando sem refeições e com meta',
      (tester) async {
    final repo = _FakeMealsRepository()..setInitialGoal(2000);
    await tester.pumpWidget(_wrap(const MealsScreen(), repo));
    await pumpFrames(tester);

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
    await pumpFrames(tester);

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
    await pumpFrames(tester);

    expect(find.textContaining('over goal'), findsOneWidget);
  });

  testWidgets('sem meta mostra hint de definir', (tester) async {
    final repo = _FakeMealsRepository();
    await tester.pumpWidget(_wrap(const MealsScreen(), repo));
    await pumpFrames(tester);

    expect(find.textContaining('Set a goal'), findsOneWidget);
  });
}
