enum BetChoice { under, equal, over }

extension BetChoiceLabel on BetChoice {
  String get label => switch (this) {
    BetChoice.under => 'MOINS DE 7',
    BetChoice.equal => 'ÉGAL 7',
    BetChoice.over => 'PLUS DE 7',
  };

  String get shortLabel => switch (this) {
    BetChoice.under => 'MOINS 7',
    BetChoice.equal => 'ÉGAL 7',
    BetChoice.over => 'PLUS 7',
  };

  /// Code attendu par la fonction serveur `play_round` / l'Edge Function
  /// `play-game` (voir supabase/migrations/0002_play_round.sql).
  String get serverCode => switch (this) {
    BetChoice.under => 'UNDER',
    BetChoice.equal => 'EQUAL',
    BetChoice.over => 'OVER',
  };
}

BetChoice betChoiceFromServerCode(String code) => switch (code) {
  'UNDER' => BetChoice.under,
  'EQUAL' => BetChoice.equal,
  'OVER' => BetChoice.over,
  _ => throw ArgumentError('Code de résultat serveur inconnu: $code'),
};
