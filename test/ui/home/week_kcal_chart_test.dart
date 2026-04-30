import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/ui/core/themes/app_theme.dart';
import 'package:mamba_growth/ui/home/state/aggregations.dart';
import 'package:mamba_growth/ui/home/widgets/week_kcal_chart.dart';

void main() {
  WeekKcalChartData makeData({int firstFuture = 7, int selected = 3}) {
    final start = DateTime(2026, 4, 26);
    return WeekKcalChartData(
      days: List.generate(
        7,
        (i) => DayKcal(
          day: start.add(Duration(days: i)),
          kcal: 1000 + i * 100,
        ),
      ),
      goal: 2000,
      todayIndex: 3,
      selectedIndex: selected,
      firstFutureIndex: firstFuture,
    );
  }

  Future<void> pump(WidgetTester tester, Widget w) async {
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
        home: Scaffold(body: w),
      ),
    );
  }

  testWidgets('builds without throwing', (tester) async {
    await pump(
      tester,
      WeekKcalChart(data: makeData(), onSelectDay: (_) {}),
    );
    expect(find.byType(WeekKcalChart), findsOneWidget);
  });

  testWidgets('semantics label includes counts and selection', (tester) async {
    await pump(
      tester,
      WeekKcalChart(data: makeData(), onSelectDay: (_) {}),
    );
    final semantics = tester.getSemantics(find.byType(WeekKcalChart));
    expect(
      semantics.label,
      contains('Calorie chart'),
    );
    expect(semantics.label, contains('1300 kcal'));
  });

  testWidgets('tapping a past column calls onSelectDay', (tester) async {
    int? tapped;
    await pump(
      tester,
      WeekKcalChart(
        data: makeData(firstFuture: 4, selected: 3),
        onSelectDay: (i) => tapped = i,
      ),
    );
    final box = tester.getRect(find.byType(WeekKcalChart));
    // Column 1 center (Monday): 16dp left pad, then 1.5 columns out.
    final colWidth = (box.width - 32) / 7;
    final tapX = box.left + 16 + colWidth * 1.5;
    final tapY = box.center.dy;
    await tester.tapAt(Offset(tapX, tapY));
    expect(tapped, 1);
  });

  testWidgets('tapping a future column does not call onSelectDay',
      (tester) async {
    int? tapped;
    await pump(
      tester,
      WeekKcalChart(
        data: makeData(firstFuture: 4, selected: 3),
        onSelectDay: (i) => tapped = i,
      ),
    );
    final box = tester.getRect(find.byType(WeekKcalChart));
    final colWidth = (box.width - 32) / 7;
    final tapX = box.left + 16 + colWidth * 5.5; // column 5
    await tester.tapAt(Offset(tapX, box.center.dy));
    expect(tapped, isNull);
  });
}
