import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Initials avatar (no photos are stored in V1).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = AppSizes.avatarMd,
    this.tone = AppTone.brand,
  });

  final String name;
  final double size;
  final AppTone tone;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(tone);

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.background,
        child: Text(
          initialsOf(name),
          style: context.textStyles.titleMedium?.copyWith(
            color: colors.foreground,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
