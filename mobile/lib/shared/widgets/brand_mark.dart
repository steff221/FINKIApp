import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final bool onDark;
  const BrandMark({super.key, this.size = 40, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/finki_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
