import 'package:done/main.dart';
import 'package:done/models.dart';
import 'package:done/screens/splash_gate.dart';
import 'package:done/store.dart';
import 'package:done/theme.dart';
import 'package:done/widgets/logo_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host({bool reduceMotion = false}) => MaterialApp(
      theme: buildTheme(Brightness.light, webFonts: false),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const SplashGate(child: Text('home')),
    );

RenderObject logoPaint(WidgetTester tester) => tester.renderObject(
      find.descendant(of: find.byType(LogoMark), matching: find.byType(CustomPaint)),
    );

void main() {
  testWidgets('starts on the logo, not on the app', (tester) async {
    await tester.pumpWidget(host());

    expect(find.byType(LogoMark), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('draws the ring first, then the check', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));
    expect(logoPaint(tester), paintsExactlyCountTimes(#drawPath, 1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(logoPaint(tester), paintsExactlyCountTimes(#drawPath, 2));
  });

  testWidgets('hands over to the app once the mark is drawn', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(LogoMark), findsNothing);
  });

  testWidgets('is skipped when animations are reduced', (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(LogoMark), findsNothing);
  });

  testWidgets('DoneApp plays the splash before the home screen', (tester) async {
    await initializeDateFormatting('fr_FR');
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = TodoStore(prefs, projects: <Project>[]);

    await tester.pumpWidget(DoneApp(store: store, webFonts: false));
    expect(find.byType(LogoMark), findsOneWidget);
    expect(find.text('Aucun projet. Nommez-en un ci-dessous.'), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('Aucun projet. Nommez-en un ci-dessous.'), findsOneWidget);
  });
}
