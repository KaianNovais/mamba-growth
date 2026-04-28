import 'package:flutter_test/flutter_test.dart';

import 'package:mamba_growth/main.dart';

void main() {
  testWidgets('App boots with the design system theme', (tester) async {
    await tester.pumpWidget(const MambaGrowthApp());
    expect(find.text('Mamba Growth'), findsOneWidget);
  });
}
