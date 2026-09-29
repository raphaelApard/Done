import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'seed.dart';

/// App state — projects and theme — persisted locally.
class TodoStore extends ChangeNotifier {
  TodoStore(this._prefs, {required this.projects, this.themeMode = ThemeMode.system});

  static const _kProjects = 'projects';
  static const _kTheme = 'theme';

  final SharedPreferences _prefs;
  final List<Project> projects;
  ThemeMode themeMode;

  /// Restores the saved state. On the first launch (or if the saved data is
  /// unreadable) the store starts from [seedProjects] when [seed] is true.
  static Future<TodoStore> load({SharedPreferences? prefs, bool seed = true}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final fallback = seed ? seedProjects() : <Project>[];
    var projects = fallback;
    final raw = p.getString(_kProjects);
    if (raw != null) {
      try {
        projects = (jsonDecode(raw) as List)
            .map((j) => Project.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {
        projects = fallback;
      }
    }
    final theme = switch (p.getString(_kTheme)) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    return TodoStore(p, projects: projects, themeMode: theme);
  }

  void _commit() {
    unawaited(_prefs.setString(_kProjects, jsonEncode(projects.map((p) => p.toJson()).toList())));
    notifyListeners();
  }

  int get totalLeft => projects.fold(0, (n, p) => n + p.total - p.doneCount);

  Project? byId(String id) => projects.where((p) => p.id == id).firstOrNull;

  // — Theme

  /// Switches to the opposite of the brightness currently on screen.
  void toggleTheme(Brightness current) {
    themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    unawaited(_prefs.setString(_kTheme, themeMode == ThemeMode.dark ? 'dark' : 'light'));
    notifyListeners();
  }

  // — Projects

  void addProject(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    projects.add(Project(name: n));
    _commit();
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    _commit();
  }

  // — Tasks

  void addTask(String projectId, String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    final p = byId(projectId);
    if (p == null) return;
    // Keep completed tasks after the open ones.
    p.tasks.insert(p.open.length, Task(title: t));
    _commit();
  }

  /// Renames a task; an empty title deletes it.
  void editTask(String projectId, String taskId, String title) {
    final p = byId(projectId);
    if (p == null) return;
    final t = title.trim();
    if (t.isEmpty) {
      p.tasks.removeWhere((x) => x.id == taskId);
    } else {
      final task = p.tasks.where((x) => x.id == taskId).firstOrNull;
      if (task == null) return;
      task.title = t;
    }
    _commit();
  }

  void deleteTask(String projectId, String taskId) {
    byId(projectId)?.tasks.removeWhere((x) => x.id == taskId);
    _commit();
  }

  void toggleTask(String projectId, String taskId) {
    final p = byId(projectId);
    if (p == null) return;
    final t = p.tasks.where((x) => x.id == taskId).firstOrNull;
    if (t == null) return;
    t.done = !t.done;
    // Open tasks keep their order; a completed task drops to the bottom and a
    // reopened one goes back at the end of the open tasks.
    p.tasks
      ..remove(t)
      ..insert(t.done ? p.tasks.length : p.open.length, t);
    _commit();
  }

  /// Moves an open task. Both indices refer to [Project.open]; [newIndex] is
  /// the final position, as given by `onReorderItem`.
  void reorderOpen(String projectId, int oldIndex, int newIndex) {
    final p = byId(projectId);
    if (p == null) return;
    final open = p.open;
    if (oldIndex == newIndex) return;
    open.insert(newIndex, open.removeAt(oldIndex));
    final completed = p.completed; // read before the list is cleared
    p.tasks
      ..clear()
      ..addAll([...open, ...completed]);
    _commit();
  }

  void clearDone(String projectId) {
    byId(projectId)?.tasks.removeWhere((t) => t.done);
    _commit();
  }
}
