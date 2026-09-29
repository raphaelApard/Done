import 'package:flutter/material.dart';

/// Floating pill-shaped input used to add a project or a task.
/// Submitting keeps the focus so several items can be entered in a row.
class Composer extends StatefulWidget {
  const Composer({super.key, required this.hint, required this.onSubmit});

  final String hint;
  final ValueChanged<String> onSubmit;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  void _submit() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: cs.brightness == Brightness.dark ? .6 : .14),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.done,
            style: Theme.of(context).textTheme.bodyLarge,
            cursorColor: cs.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: cs.outline),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton.filled(
            onPressed: _submit,
            tooltip: 'Ajouter',
            style: IconButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            icon: const Icon(Icons.add, size: 22),
          ),
        ),
      ]),
    );
  }
}
