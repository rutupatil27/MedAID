import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Rounded surface used to group information. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: borderColor == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: AppRadii.lgAll,
              side: BorderSide(color: borderColor!),
            ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
