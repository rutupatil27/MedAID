import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// MedAID logo badge used on auth screens.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = AppSizes.avatarMd});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.health_and_safety_rounded, size: size * 0.5, color: context.colors.primary),
    );
  }
}
