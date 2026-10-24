import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../game/models/bet_choice.dart';
import '../models/history_entry.dart';

/// Carte détaillée d'une partie passée (section 17 du cahier des charges).
class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final won = entry.payout > 0;
    final accent = _accentFor(entry.result);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spaceM),
      padding: const EdgeInsets.all(AppDimens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Partie #${entry.id}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              Text(
                entry.result.label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceS),
          Row(
            children: [
              _DiceChip(label: 'Dé 1', value: entry.dice1),
              const SizedBox(width: AppDimens.spaceM),
              _DiceChip(label: 'Dé 2', value: entry.dice2),
              const SizedBox(width: AppDimens.spaceM),
              _DiceChip(label: 'Total', value: entry.total),
            ],
          ),
          const SizedBox(height: AppDimens.spaceS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mise : ${AppFormatters.stake(entry.stake)} XAF  •  Cote : x${entry.odds.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                won
                    ? '+${AppFormatters.stake(entry.payout)} XAF'
                    : '-${AppFormatters.stake(entry.stake)} XAF',
                style: TextStyle(
                  color: won ? AppColors.greenBright : AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.formattedDate,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _accentFor(BetChoice choice) => switch (choice) {
    BetChoice.over => AppColors.greenBright,
    BetChoice.equal => AppColors.gold,
    BetChoice.under => AppColors.info,
  };
}

class _DiceChip extends StatelessWidget {
  const _DiceChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Text(
        '$label : $value',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
