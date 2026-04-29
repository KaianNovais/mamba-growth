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
