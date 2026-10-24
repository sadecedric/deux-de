import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/formatters.dart';

/// Carte affichant le solde virtuel (section 20 du cahier des charges).
class VirtualWalletCard extends StatelessWidget {
  const VirtualWalletCard({super.key, required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.goldDim.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text(
            'SOLDE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppFormatters.amount(balance)} XAF',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
