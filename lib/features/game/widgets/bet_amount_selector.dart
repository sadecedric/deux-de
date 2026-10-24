import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cancel_text_button.dart';

/// Contrôles de mise virtuelle : MIN / X2 / X/2 / MAX + saisie manuelle.
class BetAmountSelector extends StatelessWidget {
  const BetAmountSelector({
    super.key,
    required this.amount,
    required this.enabled,
    required this.onMin,
    required this.onDouble,
    required this.onHalf,
    required this.onMax,
    required this.onManualEdit,
  });

  final double amount;
  final bool enabled;
  final VoidCallback onMin;
  final VoidCallback onDouble;
  final VoidCallback onHalf;
  final VoidCallback onMax;
  final ValueChanged<double> onManualEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _AmountButton(label: 'MIN', onTap: enabled ? onMin : null),
            _AmountButton(label: 'X2', onTap: enabled ? onDouble : null),
            _AmountButton(label: 'X/2', onTap: enabled ? onHalf : null),
            _AmountButton(label: 'MAX', onTap: enabled ? onMax : null),
          ],
        ),
        const SizedBox(height: AppDimens.spaceS),
        GestureDetector(
          onTap: enabled ? () => _openManualInput(context) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(
                color: AppColors.goldDim.withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${AppFormatters.stake(amount)} XAF',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openManualInput(BuildContext context) async {
    final controller = TextEditingController(text: amount.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Montant de la mise'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'XAF'),
        ),
        actions: [
          CancelTextButton(onPressed: () => Navigator.of(dialogContext).pop()),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              Navigator.of(dialogContext).pop(parsed);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      onManualEdit(value);
    }
  }
}

class _AmountButton extends StatelessWidget {
  const _AmountButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: onTap != null
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
