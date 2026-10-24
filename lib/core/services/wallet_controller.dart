import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/wallet/models/wallet_transaction.dart';

/// Solde virtuel partagé entre les écrans Jeu / Profil / Portefeuille.
///
/// Phase 1-9 : source de vérité locale en mémoire. Sera remplacée par
/// Supabase (table `wallets` + Edge Function `play-game`) en Phase 13-14 ;
/// l'API publique (balance, deposit, placeBet, creditWin) restera la même.
class WalletController extends ChangeNotifier {
  WalletController._() {
    _record(type: WalletTransactionType.initialCredit, amount: _balance);
  }

  static final WalletController instance = WalletController._();
  SharedPreferences? _prefs;
  String? _storageKey;

  Future<void> loadForUser(String userId) async {
    final key = 'wallet_balance_$userId';
    if (_storageKey == key) return;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _storageKey = key;
    _balance = prefs.getDouble(key) ?? 25572903.82;
    _transactions.clear();
    _record(type: WalletTransactionType.initialCredit, amount: _balance);
    notifyListeners();
  }

  /// Sets the user's virtual balance, including a reduction or reset to zero.
  Future<void> setBalance(double amount) async {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Solde invalide');
    }
    final rounded = (amount * 100).roundToDouble() / 100;
    if (!rounded.isFinite) throw ArgumentError.value(amount, 'amount');
    final key = _storageKey;
    if (key != null) {
      final saved = await _prefs!.setDouble(key, rounded);
      if (!saved) throw StateError('Enregistrement du solde impossible.');
      if (_storageKey != key) return;
    }
    final difference = rounded - _balance;
    _balance = rounded;
    _record(type: WalletTransactionType.adjustment, amount: difference);
    notifyListeners();
  }

  void _persist() {
    final key = _storageKey;
    if (key != null) _prefs?.setDouble(key, _balance);
  }

  double _balance = 25572903.82;
  double get balance => _balance;

  final List<WalletTransaction> _transactions = [];
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void deposit(double amount) {
    if (!amount.isFinite || amount <= 0) return;
    _balance += amount;
    _record(type: WalletTransactionType.virtualDeposit, amount: amount);
    _persist();
    notifyListeners();
  }

  /// Débite la mise si le solde est suffisant. Retourne false sinon.
  bool placeBet(double stake) {
    if (!stake.isFinite || stake <= 0 || stake > _balance) return false;
    _balance -= stake;
    _record(type: WalletTransactionType.bet, amount: -stake);
    _persist();
    notifyListeners();
    return true;
  }

  void creditWin(double amount) {
    if (!amount.isFinite || amount <= 0) return;
    _balance += amount;
    _record(type: WalletTransactionType.win, amount: amount);
    _persist();
    notifyListeners();
  }

  /// Aligne le solde local sur la valeur renvoyée par le serveur
  /// (Edge Function `play-game` ou lecture de la table `wallets`).
  /// N'enregistre pas de transaction locale : le serveur l'a déjà fait.
  void syncFromServer(double balance) {
    _balance = balance;
    _persist();
    notifyListeners();
  }

  void _record({required WalletTransactionType type, required double amount}) {
    final before = _balance - amount;
    _transactions.insert(
      0,
      WalletTransaction(
        type: type,
        amount: amount,
        balanceBefore: before,
        balanceAfter: _balance,
        createdAt: DateTime.now(),
      ),
    );
  }
}
