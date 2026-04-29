import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../domain/models/meal.dart';
import '../../../utils/command.dart';

/// View model da tela de refeições.
///
/// Espelha o estado do [MealsRepository] (refeições do dia + meta) e
/// expõe valores derivados ([totalKcal], [progress], [overGoal]) que a
/// UI consome diretamente. As ações são embrulhadas em [Command1]
/// (`addMeal`, `updateMeal`, `deleteMeal`) para que a UI possa observar
/// `running`/`error`/`completed` por ação.
///
/// O `_subscribe` recria a stream quando o app volta do background em
/// um novo dia (`AppLifecycleState.resumed`), garantindo que a tela
/// nunca exiba refeições do dia anterior após "virar a meia-noite".
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

  /// Reinsere uma refeição deletada (undo do snackbar).
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

  void _onRepoChanged() {
    // O repo notifica em mudanças de meta E em mudanças de refeições
    // (add/update/delete/reinsert). Re-assinamos para capturar a snapshot
    // atual do dia — o broadcast controller do repo real também envia,
    // mas re-assinar é idempotente e deixa o VM funcionar com fakes que
    // emitem só na inscrição.
    _subscribe();
    notifyListeners();
  }

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
