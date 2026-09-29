import 'package:flutter/material.dart';

/// Round checkbox that fills in with a small "pop" when checked.
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.checked, required this.onChanged});

  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      checked: checked,
      label: checked ? 'Rouvrir la tâche' : 'Terminer la tâche',
      child: InkResponse(
        onTap: onChanged,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: checked ? 1 : 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, t, _) {
                final fill = t.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1 + .2 * (fill < .5 ? fill : 1 - fill),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(Colors.transparent, cs.primary, fill),
                      border: Border.all(
                        width: 2,
                        color: Color.lerp(cs.outline, cs.primary, fill)!,
                      ),
                    ),
                    child: Opacity(
                      opacity: fill,
                      child: Icon(Icons.check, size: 15, color: cs.onPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
