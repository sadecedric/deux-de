import 'package:flutter/foundation.dart';

import '../../features/game/models/bet_choice.dart';
import '../../features/history/models/history_entry.dart';

/// Historique local partagé entre le jeu et l'onglet Résultats.
class GameHistoryController extends ChangeNotifier {
  GameHistoryController._();

  static final instance = GameHistoryController._();
  final List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  void addRound({
    required int dice1,
    required int dice2,
    required BetChoice result,
    required double stake,
    required double odds,
    required double payout,
  }) {
    _entries.insert(
      0,
      HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch,
        dice1: dice1,
        dice2: dice2,
        result: result,
        stake: stake,
        odds: odds,
        payout: payout,
        playedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
