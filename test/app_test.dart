import 'package:done/main.dart';
import 'package:done/models.dart';
import 'package:done/screens/home_screen.dart';
import 'package:done/store.dart';
import 'package:done/widgets/check_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TodoStore> storeWith(List<Project> projects) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return TodoStore(prefs, projects: projects);
}

Future<void> pumpApp(WidgetTester tester, TodoStore store) async {
  await tester.pumpWidget(DoneApp(store: store, webFonts: false));
  await tester.pumpAndSettle();
}

/// Types into the composer, which is the last text field on screen.
Future<void> compose(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).last, text);
  await tester.tap(find.byTooltip('Ajouter'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('labels', () {
    test('formats the date in French', () {
      expect(todayLabel(DateTime(2026, 9, 29)), 'Mardi 29 septembre');
    });

    test('summarises the tasks left', () {
      expect(summaryLabel(0), 'Tout est fait, bravo.');
      expect(summaryLabel(1), 'Encore 1 tâche à faire');
      expect(summaryLabel(5), 'Encore 5 tâches à faire');
    });
  });

  group('home', () {
    testWidgets('lists projects with their status', (tester) async {
      final store = await storeWith([
        Project(name: 'Maison', tasks: [Task(title: 'a'), Task(title: 'b')]),
        Project(name: 'Voyage', tasks: [Task(title: 'c'), Task(title: 'd', done: true)]),
      ]);
      await pumpApp(tester, store);

      expect(find.text('Encore 3 tâches à faire'), findsOneWidget);
      expect(find.text('Maison'), findsOneWidget);
      expect(find.text('2 restantes'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      expect(find.text('Voyage'), findsOneWidget);
      expect(find.text('1 restante'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('invites to create a first project', (tester) async {
      await pumpApp(tester, await storeWith([]));
      expect(find.text('Tout est fait, bravo.'), findsOneWidget);
      expect(find.text('Aucun projet. Nommez-en un ci-dessous.'), findsOneWidget);
    });

    testWidgets('adds a project from the composer', (tester) async {
      final store = await storeWith([]);
      await pumpApp(tester, store);

      await compose(tester, 'Lectures');

      expect(find.text('Lectures'), findsOneWidget);
      expect(find.text('Aucune tâche'), findsOneWidget);
      expect(store.projects.single.name, 'Lectures');
    });

    testWidgets('deletes a project after confirmation', (tester) async {
      final store = await storeWith([Project(name: 'Maison')]);
      await pumpApp(tester, store);

      await tester.tap(find.byTooltip('Supprimer le projet'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer « Maison » ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(store.projects, isEmpty);
      expect(find.text('Maison'), findsNothing);
    });

    testWidgets('keeps the project when the deletion is cancelled', (tester) async {
      final store = await storeWith([Project(name: 'Maison')]);
      await pumpApp(tester, store);

      await tester.tap(find.byTooltip('Supprimer le projet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(store.projects, hasLength(1));
      expect(find.text('Maison'), findsOneWidget);
    });

    testWidgets('switches the theme', (tester) async {
      final store = await storeWith([]);
      await pumpApp(tester, store);
      expect(store.themeMode, ThemeMode.system);

      await tester.tap(find.byTooltip('Changer de thème'));
      await tester.pumpAndSettle();

      expect(store.themeMode, ThemeMode.dark);
      final theme = Theme.of(tester.element(find.byType(HomeScreen)));
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('project', () {
    Future<TodoStore> openProject(WidgetTester tester, List<Task> tasks) async {
      final store = await storeWith([Project(name: 'Maison', tasks: tasks)]);
      await pumpApp(tester, store);
      await tester.tap(find.text('Maison'));
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('shows open and completed tasks', (tester) async {
      await openProject(tester, [Task(title: 'Peindre'), Task(title: 'Ranger', done: true)]);

      expect(find.text('Peindre'), findsOneWidget);
      expect(find.text('Terminées (1)'), findsOneWidget);
      expect(find.text('Ranger'), findsOneWidget);
      expect(find.text('1 sur 2 terminées'), findsOneWidget);
    });

    testWidgets('goes back to the projects', (tester) async {
      await openProject(tester, []);
      expect(find.text('Notez une première tâche ci-dessous.'), findsOneWidget);

      await tester.tap(find.text('Projets'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune tâche'), findsOneWidget);
    });

    testWidgets('adds a task', (tester) async {
      final store = await openProject(tester, []);

      await compose(tester, 'Appeler le plombier');

      expect(find.text('Appeler le plombier'), findsOneWidget);
      expect(store.projects.single.tasks.single.title, 'Appeler le plombier');
    });

    testWidgets('checking a task moves it to the completed section', (tester) async {
      final store = await openProject(tester, [Task(title: 'Peindre'), Task(title: 'Ranger')]);

      await tester.tap(find.byType(CheckCircle).first);
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks.first.title, 'Ranger');
      expect(find.text('Terminées (1)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CheckCircle && w.checked), findsOneWidget);
    });

    testWidgets('reopens a completed task', (tester) async {
      final store = await openProject(tester, [Task(title: 'Ranger', done: true)]);

      await tester.tap(find.byType(CheckCircle));
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks.single.done, isFalse);
      expect(find.textContaining('Terminées'), findsNothing);
    });

    testWidgets('edits a task inline', (tester) async {
      final store = await openProject(tester, [Task(title: 'Peindre')]);

      await tester.tap(find.text('Peindre'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Peindre'), 'Repeindre');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks.single.title, 'Repeindre');
      expect(find.text('Repeindre'), findsOneWidget);
    });

    testWidgets('clearing the text of a task deletes it', (tester) async {
      final store = await openProject(tester, [Task(title: 'Peindre')]);

      await tester.tap(find.text('Peindre'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Peindre'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks, isEmpty);
    });

    testWidgets('deletes a task after confirmation', (tester) async {
      final store = await openProject(tester, [Task(title: 'Peindre')]);

      await tester.tap(find.byTooltip('Supprimer la tâche'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer cette tâche ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks, isEmpty);
    });

    testWidgets('clears the completed tasks', (tester) async {
      final store = await openProject(tester, [
        Task(title: 'Peindre'),
        Task(title: 'Ranger', done: true),
      ]);

      await tester.tap(find.text('Tout effacer'));
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks.map((t) => t.title), ['Peindre']);
      expect(find.textContaining('Terminées'), findsNothing);
    });

    testWidgets('collapses the completed section', (tester) async {
      await openProject(tester, [Task(title: 'Ranger', done: true)]);

      await tester.tap(find.text('Terminées (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Ranger'), findsNothing);
    });

    testWidgets('reorders open tasks by dragging the handle', (tester) async {
      final store = await openProject(tester, [
        Task(title: 'a'),
        Task(title: 'b'),
        Task(title: 'c'),
      ]);

      await tester.drag(find.byIcon(Icons.drag_indicator).first, const Offset(0, 140));
      await tester.pumpAndSettle();

      expect(store.projects.single.tasks.first.title, isNot('a'));
      expect(store.projects.single.tasks.map((t) => t.title), containsAll(['a', 'b', 'c']));
    });
  });
}
