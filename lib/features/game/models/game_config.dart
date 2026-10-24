import 'bet_choice.dart';

/// Configuration du jeu (cotes, limites de mise). En Phase 1-2 ces valeurs
/// sont mockées ; elles proviendront plus tard de la table Supabase `game_config`.
class GameConfig {
  const GameConfig({
    required this.underOdds,
    required this.equalOdds,
    required this.overOdds,
    required this.minStake,
    required this.maxStake,
  });

  final double underOdds;
  final double equalOdds;
  final double overOdds;
  final double minStake;
  final double maxStake;

  double oddsFor(BetChoice choice) => switch (choice) {
    BetChoice.under => underOdds,
    BetChoice.equal => equalOdds,
    BetChoice.over => overOdds,
  };

  static const mock = GameConfig(
    underOdds: 2.3,
    equalOdds: 5.8,
    overOdds: 2.3,
    minStake: 100,
    maxStake: 50000,
  );
}
