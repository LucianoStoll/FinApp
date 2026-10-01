import 'package:flutter/material.dart';

/// Compara os campos com a abertura do formulário; foco não conta como edição.
class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard(
      {super.key,
      required this.value,
      required this.changes,
      required this.builder});
  final Object Function() value;
  final List<Listenable> changes;
  final Widget Function(BuildContext context, VoidCallback cancel) builder;

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  late final Object _original;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _original = widget.value();
    for (final change in widget.changes) {
      change.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final change in widget.changes) {
      change.removeListener(_refresh);
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _cancel() async {
    if (_confirming) return;
    if (widget.value() != _original) {
      _confirming = true;
      final discard = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('Descartar alterações?'),
                content: const Text(
                    'As alterações deste formulário não foram salvas.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Continuar editando')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Descartar')),
                ],
              ));
      _confirming = false;
      if (!mounted || discard != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: widget.value() == _original,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _cancel();
        },
        child: widget.builder(context, _cancel),
      );
}
