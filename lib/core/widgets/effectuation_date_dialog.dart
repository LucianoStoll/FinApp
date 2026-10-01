import 'package:flutter/material.dart';

/// Retorna null se a pessoa cancelar. Vencimentos diferentes de hoje exigem
/// escolher explicitamente a data que movimentará o saldo realizado.
Future<DateTime?> chooseEffectuationDate(
    BuildContext context, DateTime dueDate) async {
  final today = DateUtils.dateOnly(DateTime.now());
  if (DateUtils.isSameDay(dueDate, today)) return today;
  return showDialog<DateTime>(
      context: context,
      builder: (dialog) => AlertDialog(
            title: const Text('Quando contabilizar o movimento?'),
            content: Text(
                'O vencimento é ${dueDate.day.toString().padLeft(2, '0')}/'
                '${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}. '
                'Escolha quando o movimento deve entrar no saldo realizado.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(dialog, today),
                  child: const Text('Contabilizar hoje')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialog, dueDate),
                  child: const Text('Contabilizar no vencimento')),
            ],
          ));
}
