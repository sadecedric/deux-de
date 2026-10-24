import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../models/bet_choice.dart';

/// Carte sélectionnable pour un choix de cote (PLUS DE 7 / ÉGAL 7 / MOINS DE 7).
class BetOptionCard extends StatelessWidget {
  const BetOptionCard({
    super.key,
    required this.choice,
    required this.odds,
    required this.isSelected,
    required this.onTap,
  });

  final BetChoice choice;
  final double odds;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(choice);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          transform: isSelected
              ? Matrix4.translationValues(0.0, -3.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                choice.shortLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'x${odds.toStringAsFixed(1)}',
                style: TextStyle(
                  color: isSelected ? accent : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(BetChoice choice) => switch (choice) {
    BetChoice.over => AppColors.greenBright,
    BetChoice.equal => AppColors.gold,
    BetChoice.under => AppColors.info,
  };
}
