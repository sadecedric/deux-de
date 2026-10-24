import 'package:intl/intl.dart';

import '../../game/models/bet_choice.dart';

/// Représentation locale d'une partie passée. Alimentée plus tard par la
/// table Supabase `games`/`bets`.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.dice1,
    required this.dice2,
    required this.result,
    required this.stake,
    required this.odds,
    required this.payout,
    required this.playedAt,
  });

  final int id;
  final int dice1;
  final int dice2;
  final BetChoice result;
  final double stake;
  final double odds;
  final double payout;
  final DateTime playedAt;

  int get total => dice1 + dice2;

  String get formattedDate =>
      DateFormat("d MMMM yyyy • HH:mm", 'fr_FR').format(playedAt);

  static List<HistoryEntry> mockList() {
    final now = DateTime.now();
    return [
      HistoryEntry(
        id: 1842,
        dice1: 5,
        dice2: 3,
        result: BetChoice.over,
        stake: 400,
        odds: 2.3,
        payout: 920,
        playedAt: now.subtract(const Duration(minutes: 5)),
      ),
      HistoryEntry(
        id: 1841,
        dice1: 4,
        dice2: 2,
        result: BetChoice.under,
        stake: 500,
        odds: 2.3,
        payout: 0,
        playedAt: now.subtract(const Duration(minutes: 20)),
      ),
      HistoryEntry(
        id: 1840,
        dice1: 4,
        dice2: 3,
        result: BetChoice.equal,
        stake: 300,
        odds: 5.8,
        payout: 1740,
        playedAt: now.subtract(const Duration(hours: 1)),
      ),
      HistoryEntry(
        id: 1839,
        dice1: 6,
        dice2: 4,
        result: BetChoice.over,
        stake: 400,
        odds: 2.3,
        payout: 0,
        playedAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }
}
