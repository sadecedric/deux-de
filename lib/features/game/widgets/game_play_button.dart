import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Rangée d'actions principales : portefeuille, PLAY (gros bouton central), reset.
class GamePlayButton extends StatelessWidget {
  const GamePlayButton({
    super.key,
    required this.canPlay,
    required this.isRolling,
    required this.onPlay,
    required this.onWalletTap,
    required this.onReset,
  });

  final bool canPlay;
  final bool isRolling;
  final VoidCallback onPlay;
  final VoidCallback onWalletTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleIconButton(
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.gold,
          onTap: onWalletTap,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: canPlay && !isRolling ? onPlay : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canPlay && !isRolling
                      ? [AppColors.greenBright, AppColors.green]
                      : [AppColors.textMuted, AppColors.textMuted],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: canPlay && !isRolling
                    ? [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRolling ? Icons.hourglass_top : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isRolling ? 'EN COURS' : 'PLAY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _CircleIconButton(
          icon: Icons.refresh_rounded,
          color: AppColors.textPrimary,
          onTap: !isRolling ? onReset : null,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: onTap != null ? color : AppColors.textMuted),
      ),
    );
  }
}
