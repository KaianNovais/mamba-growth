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
  ///
  /// O repositório mantém **um único "dia atual"** compartilhado entre
  /// assinantes. Chamar com um dia diferente reconfigura o cache global —
  /// não é seguro ter dois assinantes simultâneos pedindo dias distintos.
  /// A UI atual sempre observa "hoje".
  Stream<List<Meal>> watchMealsForDay(DateTime day);

  /// Lê refeições com `eatenAt` em `[start, end)` em uma única consulta,
  /// ordenadas desc por `eatenAt`. Não toca o cache do dia corrente —
  /// seguro para histórico que cobre múltiplos dias.
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end);

  Future<Result<Meal>> addMeal({required String name, required int calories});

  /// Atualiza apenas `name` e `calories` de uma refeição existente.
  /// `eatenAt` é imutável após a criação ("horário automático" — ver spec).
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
