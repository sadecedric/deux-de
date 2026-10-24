/// Types de transaction du portefeuille virtuel (section 14 du cahier des charges).
enum WalletTransactionType {
  initialCredit,
  virtualDeposit,
  bet,
  win,
  refund,
  adjustment,
}

extension WalletTransactionTypeLabel on WalletTransactionType {
  String get label => switch (this) {
    WalletTransactionType.adjustment => 'Ajustement du solde',
    WalletTransactionType.initialCredit => 'Crédit initial',
    WalletTransactionType.virtualDeposit => 'Dépôt virtuel',
    WalletTransactionType.bet => 'Mise',
    WalletTransactionType.win => 'Gain',
    WalletTransactionType.refund => 'Remboursement',
  };
}

class WalletTransaction {
  const WalletTransaction({
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
  });

  final WalletTransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;
}
