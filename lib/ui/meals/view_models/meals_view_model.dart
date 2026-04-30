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
    // Único canal: o repo já notifica em mudanças de meta + bootstrap.
    // Mudanças de refeições chegam via stream do `_subscribe`.
    _repo.addListener(_onRepoChanged);
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
  // Cacheado: o getter era chamado 3-4× por rebuild (progress, overGoal,
  // _RingHero) e o fold é O(n). Recalculado só quando a lista emite.
  int _totalKcal = 0;

  bool get isInitialized => _repo.isInitialized;
  DateTime get day => _day;
  List<Meal> get meals => _meals;
  int get totalKcal => _totalKcal;
  int? get goal => _repo.currentGoal;
  double get progress {
    final g = goal;
    if (g == null || g == 0) return 0;
    return _totalKcal / g;
  }

  bool get overGoal {
    final g = goal;
    return g != null && _totalKcal > g;
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
      _totalKcal = list.fold(0, (sum, m) => sum + m.calories);
      notifyListeners();
    });
  }

  void _onRepoChanged() => notifyListeners();

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
    WidgetsBinding.instance.removeObserver(this);
    addMeal.dispose();
    updateMeal.dispose();
    deleteMeal.dispose();
    super.dispose();
  }
}
