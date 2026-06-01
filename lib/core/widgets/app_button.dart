import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final style = _styleFor(variant);
    if (variant == AppButtonVariant.ghost) {
      return TextButton(onPressed: onPressed, style: style, child: child);
    }
    if (variant == AppButtonVariant.secondary) {
      return OutlinedButton(onPressed: onPressed, style: style, child: child);
    }
    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}

ButtonStyle _styleFor(AppButtonVariant variant) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  final size = const Size(0, 48);

  switch (variant) {
    case AppButtonVariant.primary:
      return ElevatedButton.styleFrom(
        minimumSize: size,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      );
    case AppButtonVariant.secondary:
      return OutlinedButton.styleFrom(
        minimumSize: size,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      );
    case AppButtonVariant.ghost:
      return TextButton.styleFrom(
        minimumSize: size,
        foregroundColor: AppColors.accent,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 14),
      );
  }
}
