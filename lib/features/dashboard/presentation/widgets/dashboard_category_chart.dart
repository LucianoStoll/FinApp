import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/money_minor.dart';
import '../../domain/entities/dashboard_summary.dart';

const _chartColors = [
  SomiaColors.blue,
  SomiaColors.red,
  SomiaColors.purple,
  SomiaColors.green,
  SomiaColors.yellow,
  Color(0xFF8F9BB7)
];

/// Distribuição mensal compartilhada entre desktop e celular.
class DashboardCategoryChart extends StatelessWidget {
  const DashboardCategoryChart({super.key, required this.currency});
  final DashboardCurrencySummary currency;

  @override
  Widget build(BuildContext context) => currency.expensesByCategory.isEmpty
              ? const SizedBox(
                  height: 220,
                  child: Center(child: Text('Nenhuma despesa neste mês.')))
              : LayoutBuilder(builder: (context, box) {
                  final wide = box.maxWidth >= 350 &&
                      MediaQuery.textScalerOf(context).scale(16) < 24;
                  final total = currency.expensesByCategory
                      .fold<int>(0, (sum, item) => sum + item.amountMinor);
                  final donut = SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(alignment: Alignment.center, children: [
                        CustomPaint(
                            size: const Size(160, 160),
                            painter:
                                _DonutPainter(currency.expensesByCategory)),
                        Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                      child: Text(
                                          MoneyMinor.display(
                                              total, currency.currencyCode),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                  Text('Total do mês',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: SomiaColors.muted)),
                                ])),
                      ]));
                  final legend = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0;
                            i < currency.expensesByCategory.length;
                            i++)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(children: [
                                CircleAvatar(
                                    radius: 5,
                                    backgroundColor:
                                        _chartColors[i % _chartColors.length]),
                                const SizedBox(width: 9),
                                Expanded(
                                    child: Text(
                                        currency.expensesByCategory[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 7),
                                Text(
                                    '${total == 0 ? 0 : (currency.expensesByCategory[i].amountMinor * 100 / total).round()}%',
                                    style: const TextStyle(
                                        color: SomiaColors.muted)),
                              ]))
                      ]);
                  return ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 220),
                      child: wide
                          ? Row(children: [
                              donut,
                              const SizedBox(width: 18),
                              Expanded(child: legend)
                            ])
                          : Column(children: [
                              donut,
                              const SizedBox(height: 12),
                              legend
                            ]));
                });
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.categories);
  final List<DashboardCategoryExpense> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final total =
        categories.fold<int>(0, (sum, item) => sum + item.amountMinor);
    if (total <= 0) return;
    final rect = Rect.fromLTWH(13, 13, size.width - 26, size.height - 26);
    var start = -math.pi / 2;
    for (var i = 0; i < categories.length; i++) {
      final sweep = categories[i].amountMinor / total * math.pi * 2;
      canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = _chartColors[i % _chartColors.length]
            ..strokeCap = StrokeCap.butt
            ..style = PaintingStyle.stroke
            ..strokeWidth = 23);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories;
}
