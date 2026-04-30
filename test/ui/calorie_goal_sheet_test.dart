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
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end) async => [];
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
