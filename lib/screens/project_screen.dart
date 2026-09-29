import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../todo_scope.dart';
import '../widgets/check_circle.dart';
import '../widgets/composer.dart';
import '../widgets/confirm_dialog.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool _doneOpen = true;

  @override
  Widget build(BuildContext context) {
    final store = TodoScope.of(context);
    final project = store.byId(widget.projectId);
    if (project == null) return const Scaffold();

    final tints = Theme.of(context).extension<ProjectTints>()!;
    final tint = tints.forIndex(store.projects.indexOf(project));
    final ink = tints.ink;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final open = project.open;
    final done = project.completed;

    return Scaffold(
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Header(project: project, tint: tint, ink: ink)),
          if (open.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  project.total == 0
                      ? 'Notez une première tâche ci-dessous.'
                      : 'Tout est coché. Ajoutez la suite ci-dessous.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverReorderableList(
                itemCount: open.length,
                onReorderItem: (from, to) => store.reorderOpen(project.id, from, to),
                proxyDecorator: (child, _, animation) => AnimatedBuilder(
                  animation: animation,
                  builder: (_, _) => Material(
                    elevation: 8 * animation.value,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                    child: child,
                  ),
                ),
                itemBuilder: (context, i) => Padding(
                  key: ValueKey(open[i].id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskTile(projectId: project.id, task: open[i], index: i),
                ),
              ),
            ),
          if (done.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _doneOpen = !_doneOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        AnimatedRotation(
                          turns: _doneOpen ? 0 : -.25,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Text('Terminées (${done.length})', style: tt.labelMedium),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => store.clearDone(project.id),
                    child: const Text('Tout effacer'),
                  ),
                ]),
              ),
            ),
            if (_doneOpen)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: done.length,
                  itemBuilder: (_, i) => _DoneTile(projectId: project.id, task: done[i]),
                ),
              ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
        ]),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: Composer(
            hint: 'Ajouter une tâche…',
            onSubmit: (title) => store.addTask(project.id, title),
          ),
        ),
      ]),
    );
  }
}

Future<void> _confirmDeleteTask(BuildContext context, String projectId, Task task) async {
  final store = TodoScope.of(context);
  final ok = await confirmDelete(
    context,
    title: 'Supprimer cette tâche ?',
    body: '« ${task.title} » sera supprimée définitivement.',
  );
  if (ok) store.deleteTask(projectId, task.id);
}

class _Header extends StatelessWidget {
  const _Header({required this.project, required this.tint, required this.ink});

  final Project project;
  final Color tint, ink;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final n = project.total;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 20),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Material(
          color: ink.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back, size: 16, color: ink),
                const SizedBox(width: 6),
                Text('Projets', style: tt.labelMedium?.copyWith(color: ink)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(project.name, style: tt.headlineMedium?.copyWith(color: ink)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: project.progress),
            duration: const Duration(milliseconds: 320),
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              color: ink,
              backgroundColor: ink.withValues(alpha: .12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${project.doneCount} sur $n terminée${n > 1 ? 's' : ''}',
          style: tt.labelSmall?.copyWith(color: ink.withValues(alpha: .75), fontSize: 13),
        ),
      ]),
    );
  }
}

/// Open task: check circle, text editable on tap, drag handle to reorder.
class _TaskTile extends StatefulWidget {
  const _TaskTile({required this.projectId, required this.task, required this.index});

  final String projectId;
  final Task task;
  final int index;

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _editing = false;
  late final _ctrl = TextEditingController(text: widget.task.title);

  void _startEditing() => setState(() {
        _ctrl.text = widget.task.title;
        _editing = true;
      });

  void _cancel() => setState(() => _editing = false);

  /// Saves the edit. An empty title deletes the task.
  void _commit() {
    if (!_editing) return;
    setState(() => _editing = false);
    TodoScope.of(context).editTask(widget.projectId, widget.task.id, _ctrl.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TodoScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.fromLTRB(2, 4, 6, 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        ReorderableDragStartListener(
          index: widget.index,
          child: SizedBox(
            width: 28,
            height: 44,
            child: Icon(Icons.drag_indicator, size: 18, color: cs.outline),
          ),
        ),
        CheckCircle(
          checked: false,
          onChanged: () => store.toggleTask(widget.projectId, widget.task.id),
        ),
        Expanded(
          child: _editing
              ? CallbackShortcuts(
                  bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    onSubmitted: (_) => _commit(),
                    onTapOutside: (_) => _commit(),
                    style: tt.bodyLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                    ),
                  ),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _startEditing,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(widget.task.title, style: tt.bodyLarge),
                  ),
                ),
        ),
        IconButton(
          tooltip: 'Supprimer la tâche',
          onPressed: () => _confirmDeleteTask(context, widget.projectId, widget.task),
          icon: Icon(Icons.delete_outline, size: 20, color: cs.outline),
        ),
      ]),
    );
  }
}

/// Completed task: struck through, tap the circle to reopen.
class _DoneTile extends StatelessWidget {
  const _DoneTile({required this.projectId, required this.task});

  final String projectId;
  final Task task;

  @override
  Widget build(BuildContext context) {
    final store = TodoScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 6),
      child: Row(children: [
        CheckCircle(checked: true, onChanged: () => store.toggleTask(projectId, task.id)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              task.title,
              style: tt.bodyLarge?.copyWith(
                color: cs.outline,
                decoration: TextDecoration.lineThrough,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Supprimer la tâche',
          onPressed: () => _confirmDeleteTask(context, projectId, task),
          icon: Icon(Icons.delete_outline, size: 20, color: cs.outline),
        ),
      ]),
    );
  }
}
