import 'package:flutter/material.dart';

/// Identidade visual oficial, usando os mesmos desenhos dos ícones nativos.
class SomiaBrand extends StatelessWidget {
  const SomiaBrand({super.key, this.symbolOnly = false, this.height = 36});
  final bool symbolOnly;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        symbolOnly
            ? 'assets/branding/somia_symbol.png'
            : 'assets/branding/somia_horizontal.png',
        height: height,
        width: symbolOnly ? height : height * 1740 / 560,
        fit: BoxFit.contain,
        semanticLabel: 'Somia',
      );
}
