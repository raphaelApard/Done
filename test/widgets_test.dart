import 'package:done/theme.dart';
import 'package:done/widgets/check_circle.dart';
import 'package:done/widgets/composer.dart';
import 'package:done/widgets/confirm_dialog.dart';
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

  group('Composer', () {
    testWidgets('submits the trimmed text and clears the field', (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(host(Composer(hint: 'Nouveau…', onSubmit: submitted.add)));

      await tester.enterText(find.byType(TextField), '  Courses ');
      await tester.tap(find.byTooltip('Ajouter'));
      await tester.pump();

      expect(submitted, ['Courses']);
      expect(find.text('Courses'), findsNothing);
    });

    testWidgets('submits on the keyboard action', (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(host(Composer(hint: 'Nouveau…', onSubmit: submitted.add)));

      await tester.enterText(find.byType(TextField), 'Lire');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, ['Lire']);
    });

    testWidgets('ignores blank input', (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(host(Composer(hint: 'Nouveau…', onSubmit: submitted.add)));

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Ajouter'));
      await tester.pump();

      expect(submitted, isEmpty);
    });
  });

  group('confirmDelete', () {
    Future<bool?> open(WidgetTester tester, String tapLabel) async {
      bool? result;
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              result = await confirmDelete(context, title: 'Supprimer ?', body: 'Définitif.'),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer ?'), findsOneWidget);
      await tester.tap(find.text(tapLabel));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('resolves true on Supprimer', (tester) async {
      expect(await open(tester, 'Supprimer'), isTrue);
    });

    testWidgets('resolves false on Annuler', (tester) async {
      expect(await open(tester, 'Annuler'), isFalse);
    });
  });
}
