import 'package:flutter/material.dart';

/// Mesma explicação no resumo e nas configurações.
Future<void> showBalanceHelp(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como os saldos são calculados'),
        scrollable: true,
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo efetivado',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Saldo inicial das contas mais entradas e menos saídas '
                'efetivadas até o último dia do mês selecionado. '
                'É um saldo acumulado, não apenas o resultado do mês.'),
            SizedBox(height: 16),
            Text('Saldo projetado',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Saldo efetivado mais receitas e menos despesas pendentes '
                'até o fim do mês, incluindo pendências de meses anteriores. '
                'É usada a data de efetivação quando preenchida; caso contrário, '
                'a de vencimento.'),
            SizedBox(height: 16),
            Text('Receitas, despesas e gráficos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Incluem efetivados e previstos. O movimento entra no mês '
                'da efetivação; se não foi efetivado, no mês do vencimento. '
                'É usado o valor efetivado ou, enquanto pendente, o previsto. '
                'A data de lançamento não define o mês do resumo.'),
            SizedBox(height: 16),
            Text('Contas e transferências',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Só contas com “Incluir no saldo do mês” ativado entram no '
                'saldo consolidado. Cada conta mantém seu próprio saldo. '
                '“Incluir em análises” controla receitas, despesas e gráficos '
                'separadamente. Transferências alteram os saldos das contas, '
                'mas não são receitas nem despesas. Uma transferência para '
                'uma conta excluída reduz o saldo consolidado.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );

class BalanceHelpButton extends StatelessWidget {
  const BalanceHelpButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Entender os saldos',
        icon: const Icon(Icons.help_outline),
        onPressed: () => showBalanceHelp(context),
      );
}
