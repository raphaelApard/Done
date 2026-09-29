import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models.dart';
import '../theme.dart';
import '../todo_scope.dart';
import '../widgets/composer.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/progress_ring.dart';
import 'project_screen.dart';

String todayLabel([DateTime? now]) {
  final s = DateFormat('EEEE d MMMM', 'fr_FR').format(now ?? DateTime.now());
  return s[0].toUpperCase() + s.substring(1);
}

String summaryLabel(int left) => left == 0
    ? 'Tout est fait, bravo.'
    : left == 1
        ? 'Encore 1 tâche à faire'
        : 'Encore $left tâches à faire';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TodoScope.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 12, 0),
            sliver: SliverList.list(children: [
              Row(children: [
                Expanded(
                  child: Text(
                    todayLabel(),
                    style: tt.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  tooltip: 'Changer de thème',
                  onPressed: () => store.toggleTheme(cs.brightness),
                  icon: Icon(
                    cs.brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(summaryLabel(store.totalLeft), style: tt.headlineMedium),
              ),
              const SizedBox(height: 32),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: store.projects.isEmpty
                ? SliverToBoxAdapter(
                    child: Text(
                      'Aucun projet. Nommez-en un ci-dessous.',
                      style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : SliverList.separated(
                    itemCount: store.projects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _ProjectCard(project: store.projects[i], index: i),
                  ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
        ]),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: Composer(hint: 'Nouveau projet…', onSubmit: store.addProject),
        ),
      ]),
    );
  }
}

Future<bool> _confirmDeleteProject(BuildContext context, Project project) => confirmDelete(
      context,
      title: 'Supprimer « ${project.name} » ?',
      body: 'Toutes ses tâches seront perdues. Cette action est définitive.',
    );

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.index});

  final Project project;
  final int index;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => ProjectScreen(projectId: project.id),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(.06, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TodoScope.of(context);
    final tints = Theme.of(context).extension<ProjectTints>()!;
    final tint = tints.forIndex(index);
    final ink = tints.ink;
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(project.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDeleteProject(context, project),
      onDismissed: (_) => store.deleteProject(project.id),
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(project.name, style: tt.titleLarge?.copyWith(color: ink)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(project.caption, style: tt.labelSmall?.copyWith(color: ink)),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              ProgressRing(
                progress: project.progress,
                label: '${project.doneCount}/${project.total}',
                color: ink,
              ),
              IconButton(
                tooltip: 'Supprimer le projet',
                onPressed: () async {
                  if (await _confirmDeleteProject(context, project)) {
                    store.deleteProject(project.id);
                  }
                },
                icon: Icon(Icons.delete_outline, size: 18, color: ink.withValues(alpha: .45)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
