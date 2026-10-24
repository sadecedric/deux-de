import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Action d'annulation cohérente dans toutes les boîtes de dialogue.
class CancelTextButton extends StatelessWidget {
  const CancelTextButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.danger,
      disabledForegroundColor: AppColors.danger.withValues(alpha: .35),
      backgroundColor: AppColors.danger.withValues(alpha: .10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.danger.withValues(alpha: .45)),
      ),
    ),
    icon: const Icon(Icons.close_rounded, size: 18),
    label: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w700)),
  );
}
