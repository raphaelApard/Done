import 'package:done/theme.dart';
import 'package:done/widgets/check_circle.dart';
import 'package:done/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.light, webFonts: false),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('CheckCircle', () {
    testWidgets('calls back on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(CheckCircle(checked: false, onChanged: () => taps++)));
      await tester.tap(find.byType(CheckCircle));
      expect(taps, 1);
    });

    testWidgets('announces the action it performs', (tester) async {
      await tester.pumpWidget(host(CheckCircle(checked: false, onChanged: () {})));
      expect(find.bySemanticsLabel('Terminer la tâche'), findsOneWidget);

      await tester.pumpWidget(host(CheckCircle(checked: true, onChanged: () {})));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Rouvrir la tâche'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('ProgressRing', () {
    testWidgets('shows its label', (tester) async {
      await tester.pumpWidget(
        host(const ProgressRing(progress: .5, label: '2/4', color: Colors.black)),
      );
      await tester.pumpAndSettle();
      expect(find.text('2/4'), findsOneWidget);
    });
  });
}
