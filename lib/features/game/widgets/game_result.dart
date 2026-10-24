import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/bet_choice.dart';
import '../models/game_state.dart';

/// Zone d'état sous le header : invite, animation en cours, ou résultat final.
class GameResult extends StatelessWidget {
  const GameResult({super.key, required this.state, this.total, this.result});

  final GameState state;
  final int? total;
  final BetChoice? result;

  @override
  Widget build(BuildContext context) {
    final String line1;
    switch (state) {
      case GameState.rolling:
        line1 = 'Lancement...';
      case GameState.result:
      case GameState.win:
      case GameState.loss:
        line1 = 'Résultat : ${total ?? '-'}';
      default:
        line1 = 'Placez un pari';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          line1,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (result != null &&
            (state == GameState.result ||
                state == GameState.win ||
                state == GameState.loss)) ...[
          const SizedBox(height: 4),
          Text(
            result!.label,
            style: TextStyle(
              color: _resultColor(result!),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Color _resultColor(BetChoice choice) => switch (choice) {
    BetChoice.over => AppColors.greenBright,
    BetChoice.equal => AppColors.gold,
    BetChoice.under => AppColors.info,
  };
}
