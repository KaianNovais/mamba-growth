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
