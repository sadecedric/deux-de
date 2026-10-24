import 'package:flutter/material.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/services/wallet_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/virtual_wallet_card.dart';
import '../widgets/balance_editor.dart';
import '../widgets/wallet_transaction_tile.dart';

/// Portefeuille virtuel : solde, ajout de crédits fictifs, historique des
/// transactions. Aucun paiement réel (section 20 du cahier des charges).
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _quickAmounts = [1000.0, 5000.0, 10000.0, 50000.0, 100000.0];

  @override
  Widget build(BuildContext context) {
    final controller = WalletController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Portefeuille')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(AppDimens.spaceM),
              children: [
                VirtualWalletCard(balance: controller.balance),
                const SizedBox(height: AppDimens.spaceM),
                FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier mon solde'),
                  onPressed: () => showBalanceEditor(context),
                ),
                const SizedBox(height: AppDimens.spaceL),
                const Text(
                  'AJOUTER DES CRÉDITS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceS),
                Wrap(
                  spacing: AppDimens.spaceS,
                  runSpacing: AppDimens.spaceS,
                  children: _quickAmounts
                      .map(
                        (amount) => _QuickAddChip(
                          amount: amount,
                          onTap: () => controller.deposit(amount),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppDimens.spaceL),
                const Text(
                  'HISTORIQUE DES TRANSACTIONS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceS),
                if (controller.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDimens.spaceL),
                    child: Center(
                      child: Text(
                        'Aucune transaction',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  for (final tx in controller.transactions)
                    WalletTransactionTile(transaction: tx),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({required this.amount, required this.onTap});

  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          border: Border.all(color: AppColors.goldDim.withValues(alpha: 0.4)),
        ),
        child: Text(
          '+ ${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
