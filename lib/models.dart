import 'dart:math';

final _random = Random();

String _uid() => '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(9999)}';

class Task {
  Task({String? id, required this.title, this.done = false}) : id = id ?? _uid();

  final String id;
  String title;
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );
}

class Project {
  Project({String? id, required this.name, List<Task>? tasks})
      : id = id ?? _uid(),
        tasks = tasks ?? [];

  final String id;
  String name;

  /// Open tasks first, in priority order, then completed tasks.
  final List<Task> tasks;

  List<Task> get open => tasks.where((t) => !t.done).toList();
  List<Task> get completed => tasks.where((t) => t.done).toList();
  int get doneCount => completed.length;
  int get total => tasks.length;
  double get progress => total == 0 ? 0 : doneCount / total;

  /// Short French status shown on the project card.
  String get caption {
    final left = total - doneCount;
    if (total == 0) return 'Aucune tâche';
    if (left == 0) return 'Terminé';
    return left == 1 ? '1 restante' : '$left restantes';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        tasks: (json['tasks'] as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
