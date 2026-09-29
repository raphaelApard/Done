import 'package:done/theme.dart';
import 'package:done/widgets/logo_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.light, webFonts: false),
      home: Scaffold(body: Center(child: child)),
    );

RenderObject paintOf(WidgetTester tester) => tester.renderObject(
      find.descendant(of: find.byType(LogoMark), matching: find.byType(CustomPaint)),
    );

void main() {
  group('geometry', () {
    // Bounds of the drawn centre line, sampled along the path.
    Rect extent(Path path) {
      Rect? box;
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d <= metric.length; d += 0.5) {
          final p = metric.getTangentForOffset(d)!.position;
          box = box == null ? Rect.fromPoints(p, p) : box.expandToInclude(Rect.fromPoints(p, p));
        }
      }
      return box!;
    }

    test('the ring and the check stay inside the grid', () {
      // The strokes are 11 wide, so their centre lines need a 5.5 margin.
      final safe = const Rect.fromLTWH(0, 0, logoGrid, logoGrid).deflate(5.5);
      for (final box in [extent(logoRingPath()), extent(logoCheckPath())]) {
        expect(safe.expandToInclude(box), safe);
      }
    });

    test('the check leaves the ring through its gap', () {
      final ring = extent(logoRingPath());
      final check = extent(logoCheckPath());
      expect(check.right, greaterThan(ring.right));
      expect(check.left, greaterThan(ring.left));
    });
  });

  group('LogoMark', () {
    testWidgets('has the requested size', (tester) async {
      await tester.pumpWidget(host(const LogoMark(
        size: 120,
        ringColor: Colors.black,
        checkColor: Colors.blue,
      )));
      expect(tester.getSize(find.byType(LogoMark)), const Size(120, 120));
    });

    testWidgets('draws the ring and the check', (tester) async {
      await tester.pumpWidget(host(const LogoMark(
        size: 100,
        ringColor: Colors.black,
        checkColor: Colors.blue,
      )));
      expect(paintOf(tester), paintsExactlyCountTimes(#drawPath, 2));
    });

    testWidgets('draws nothing at zero progress', (tester) async {
      await tester.pumpWidget(host(const LogoMark(
        size: 100,
        ringColor: Colors.black,
        checkColor: Colors.blue,
        ringProgress: 0,
        checkProgress: 0,
      )));
      expect(paintOf(tester), paintsExactlyCountTimes(#drawPath, 0));
    });

    testWidgets('draws the ring before the check', (tester) async {
      await tester.pumpWidget(host(const LogoMark(
        size: 100,
        ringColor: Colors.black,
        checkColor: Colors.blue,
        ringProgress: .5,
        checkProgress: 0,
      )));
      expect(paintOf(tester), paintsExactlyCountTimes(#drawPath, 1));
    });

    testWidgets('takes its colours from the theme', (tester) async {
      await tester.pumpWidget(host(Builder(
        builder: (context) => LogoMark.themed(context, size: 100),
      )));
      final theme = buildTheme(Brightness.light, webFonts: false);
      expect(
        paintOf(tester),
        paints
          ..path(color: theme.colorScheme.onSurface)
          ..path(color: theme.colorScheme.primary),
      );
    });

    testWidgets('is announced as the Done logo', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const LogoMark(
        size: 100,
        ringColor: Colors.black,
        checkColor: Colors.blue,
      )));
      expect(find.bySemanticsLabel('Logo Done'), findsOneWidget);
      handle.dispose();
    });
  });
}
