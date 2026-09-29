import 'package:done/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project', () {
    test('an empty project has no progress and says so', () {
      final p = Project(name: 'Vide');
      expect(p.progress, 0);
      expect(p.caption, 'Aucune tâche');
    });

    test('counts open and completed tasks', () {
      final p = Project(name: 'Maison', tasks: [
        Task(title: 'a'),
        Task(title: 'b', done: true),
        Task(title: 'c'),
      ]);
      expect(p.open.map((t) => t.title), ['a', 'c']);
      expect(p.completed.map((t) => t.title), ['b']);
      expect(p.doneCount, 1);
      expect(p.total, 3);
      expect(p.progress, closeTo(1 / 3, 1e-9));
    });

    test('caption pluralises the remaining tasks', () {
      expect(Project(name: 'p', tasks: [Task(title: 'a')]).caption, '1 restante');
      expect(
        Project(name: 'p', tasks: [Task(title: 'a'), Task(title: 'b')]).caption,
        '2 restantes',
      );
      expect(Project(name: 'p', tasks: [Task(title: 'a', done: true)]).caption, 'Terminé');
    });

    test('survives a JSON round trip', () {
      final p = Project(name: 'Lectures', tasks: [
        Task(title: 'Monte-Cristo'),
        Task(title: 'Tokarczuk', done: true),
      ]);
      final copy = Project.fromJson(p.toJson());
      expect(copy.id, p.id);
      expect(copy.name, 'Lectures');
      expect(copy.tasks.map((t) => (t.id, t.title, t.done)),
          p.tasks.map((t) => (t.id, t.title, t.done)));
    });

    test('generates distinct ids', () {
      expect(Task(title: 'a').id, isNot(Task(title: 'a').id));
    });
  });
}
