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
