import 'package:flutter/widgets.dart';

import 'store.dart';

/// Exposes the [TodoStore] to the widget tree: `TodoScope.of(context)`.
/// Widgets that read it rebuild whenever the store notifies.
class TodoScope extends InheritedNotifier<TodoStore> {
  const TodoScope({super.key, required TodoStore store, required super.child})
      : super(notifier: store);

  static TodoStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TodoScope>()!.notifier!;
}
