import 'package:flutter/material.dart';

/// Logotipo oficial de Óptica ONLY EYES S.R.L.
///
/// Se muestra contenido en sus límites para no alterar sus proporciones ni
/// recortar el lema comercial.
class BrandLogo extends StatelessWidget {
  static const assetPath = 'assets/branding/only_eyes_logo.jpg';

  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const BrandLogo({
    super.key,
    required this.width,
    required this.height,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Óptica ONLY EYES S.R.L. - Un compromiso con tu visión',
      ),
    );
  }
}
