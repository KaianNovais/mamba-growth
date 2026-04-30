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
