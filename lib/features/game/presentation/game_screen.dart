import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/wallet_controller.dart';
import '../../../core/services/game_history_controller.dart';
import '../../../core/services/local_prediction_controller.dart';
import '../../../core/services/supabase/shared_prediction_store.dart';
import 'predictor_screen.dart';
import '../models/bet_choice.dart';
import '../../history/presentation/history_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../widgets/game_art.dart';
import '../widgets/animated_game_die.dart';
import '../widgets/game_header.dart';
import '../../wallet/widgets/balance_editor.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.standaloneRound = false,
    this.initialStake = 2000,
  });

  final bool standaloneRound;
  final double initialStake;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _resultDisplayDuration = Duration(seconds: 4);

  final _wallet = WalletController.instance;
  final _history = GameHistoryController.instance;
  BetChoice? _choice;
  late double _stake;
  int? _left, _right;
  bool _rolling = false;
  bool _startingRound = false;
  String? _error;

  final _prediction = createPredictionController();
  final double _underOdds = 2.3;
  final double _equalOdds = 5.8;
  final double _overOdds = 2.3;
  final double _minStake = 100;
  final double _maxStake = 50000;
  double? _resultPayout;
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();
    _stake = widget.initialStake;
    unawaited(_prediction.initialize());
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _prediction.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final choice = _choice;
    if (choice == null || _rolling || _startingRound) return;
    final stake = _stake;
    if (stake < _minStake || stake > _maxStake || _wallet.balance < stake) {
      setState(() => _error = 'Mise invalide ou solde insuffisant');
      return;
    }
    final LocalPrediction prediction;
    _startingRound = true;
    try {
      prediction = await _prediction.forPlay();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Impossible de préparer le lancer. Vérifiez votre connexion.',
        );
      }
      return;
    } finally {
      _startingRound = false;
    }
    if (!mounted) return;
    if (!_wallet.placeBet(stake)) {
      setState(() => _error = 'Solde insuffisant');
      return;
    }
    final odds = switch (choice) {
      BetChoice.under => _underOdds,
      BetChoice.equal => _equalOdds,
      BetChoice.over => _overOdds,
    };
    final payout = prediction.result == choice ? stake * odds : 0.0;
    _resultTimer?.cancel();
    // Règlement immédiat : quitter la page ne peut pas perdre le gain.
    _wallet.creditWin(payout);
    _history.addRound(
      dice1: prediction.dice1,
      dice2: prediction.dice2,
      result: prediction.result,
      stake: stake,
      odds: odds,
      payout: payout,
    );
    setState(() {
      _left = prediction.dice1;
      _right = prediction.dice2;
      _rolling = true;
      _error = null;
      _resultPayout = null;
    });
    await Future<void>.delayed(diceRollDuration);
    if (!mounted) return;
    setState(() {
      _left = prediction.dice1;
      _right = prediction.dice2;
      _rolling = false;
      _resultPayout = payout;
    });
    _resultTimer = Timer(_resultDisplayDuration, () {
      if (!mounted) return;
      setState(() => _resultPayout = null);
    });
  }

  void _selectChoice(BetChoice choice) {
    if (_rolling) return;
    setState(() {
      _choice = choice;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: kBodyEdge,
        appBar: widget.standaloneRound
            ? AppBar(
                leading: const BackButton(),
                title: const Text('Prédire le prochain tour'),
              )
            : null,
        body: Column(
          children: [
            ListenableBuilder(
              listenable: _wallet,
              builder: (context, _) => GameHeader(
                balance: _wallet.balance,
                onAddCredits: () => showBalanceEditor(context),
                onProfileTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                onBackTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: _GameBody(
                child: ListenableBuilder(
                  listenable: _wallet,
                  builder: (context, _) => _GameCanvas(
                    rolling: _rolling,
                    error: _error,
                    resultPayout: _resultPayout,
                    left: _left,
                    right: _right,
                    choice: _choice,
                    stake: _stake,
                    overOdds: _overOdds,
                    equalOdds: _equalOdds,
                    underOdds: _underOdds,
                    onHelp: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PredictorScreen(controller: _prediction),
                      ),
                    ),
                    onChoice: _selectChoice,
                    onMin: _rolling
                        ? null
                        : () => setState(() => _stake = _minStake),
                    onDouble: _rolling
                        ? null
                        : () => setState(
                            () => _stake = min(_maxStake, _stake * 2),
                          ),
                    onHalf: _rolling
                        ? null
                        : () => setState(
                            () => _stake = max(_minStake, _stake / 2),
                          ),
                    onMax: _rolling
                        ? null
                        : () => setState(
                            () => _stake = min(_maxStake, _wallet.balance),
                          ),
                    onWallet: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    onPlay: _play,
                    onPredictor: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PredictorScreen(controller: _prediction),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zone de jeu : fond plein écran + grille de référence (474 × 735 px) mise à
/// l'échelle de l'espace disponible, alignée en haut. Le texte n'est pas
/// agrandi par le réglage de taille de police du système, pour que la mise en
/// page reste identique à la capture sur tous les téléphones.
class _GameBody extends StatelessWidget {
  const _GameBody({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final noScale = MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.noScaling);
    return Stack(
      children: [
        const Positioned.fill(child: GameBackdrop()),
        Positioned.fill(
          child: ClipRect(
            child: MediaQuery(
              data: noScale,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Toutes les positions ci-dessous sont mesurées sur la capture de référence
/// (origine = haut de la zone de jeu, juste sous l'en-tête).
class _GameCanvas extends StatelessWidget {
  const _GameCanvas({
    required this.rolling,
    required this.left,
    required this.right,
    required this.choice,
    required this.stake,
    required this.overOdds,
    required this.equalOdds,
    required this.underOdds,
    this.error,
    this.resultPayout,
    this.onHelp,
    this.onChoice,
    this.onMin,
    this.onDouble,
    this.onHalf,
    this.onMax,
    this.onWallet,
    this.onPlay,
    this.onPredictor,
  });

  final bool rolling;
  final String? error;
  final double? resultPayout;
  final int? left;
  final int? right;
  final BetChoice? choice;
  final double stake;
  final double overOdds;
  final double equalOdds;
  final double underOdds;
  final VoidCallback? onHelp;
  final ValueChanged<BetChoice>? onChoice;
  final VoidCallback? onMin;
  final VoidCallback? onDouble;
  final VoidCallback? onHalf;
  final VoidCallback? onMax;
  final VoidCallback? onWallet;
  final VoidCallback? onPlay;
  final VoidCallback? onPredictor;

  @override
  Widget build(BuildContext context) {
    Widget goldButton(double x, String label, VoidCallback? onTap) =>
        Positioned(
          left: x,
          top: 473,
          width: 98,
          height: 49,
          child: GestureDetector(
            onTap: onTap,
            child: GoldButtonFace(label: label),
          ),
        );

    Widget oddsCard(double x, String label, BetChoice value, double odds) =>
        Positioned(
          left: x,
          top: 380,
          width: 118,
          height: 79,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChoice == null ? null : () => onChoice!(value),
            child: OddsCardFace(
              label: label,
              odds: odds.toStringAsFixed(1),
              selected: choice == value,
            ),
          ),
        );

    Widget actionTile({
      required double x,
      required double width,
      required double height,
      required ActionTileKind kind,
      required Widget icon,
      required VoidCallback? onTap,
    }) => Positioned(
      left: x,
      top: 600,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: ActionTileFace(kind: kind, icon: icon),
      ),
    );

    return SizedBox(
      width: kDesignWidth,
      height: kDesignBodyHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: GameBackdropDecor()),
          Positioned(
            left: 18,
            top: 88,
            width: 64,
            height: 64,
            child: HelpBadge(onTap: onHelp),
          ),
          Positioned(
            left: 97,
            top: 98,
            width: 302,
            height: 43,
            child: PromptBar(
              text:
                  error ??
                  (rolling
                      ? 'Lancement...'
                      : resultPayout == null
                      ? 'Placez un pari'
                      : resultPayout! > 0
                      ? 'VOUS AVEZ GAGNÉ :\n${resultPayout!.toStringAsFixed(0)} XAF'
                      : 'Pas de chance'),
              tone: error != null
                  ? PromptBarTone.error
                  : rolling || resultPayout == null
                  ? PromptBarTone.neutral
                  : resultPayout! > 0
                  ? PromptBarTone.win
                  : PromptBarTone.loss,
            ),
          ),
          Positioned(
            left: 45,
            top: 189,
            width: 184,
            height: 184,
            child: AnimatedGameDie(
              value: left,
              rolling: rolling,
              initialFrontValue: 3,
              initialTopValue: 6,
            ),
          ),
          Positioned(
            left: 244,
            top: 189,
            width: 184,
            height: 184,
            child: AnimatedGameDie(
              value: right,
              rolling: rolling,
              initialFrontValue: 2,
              initialTopValue: 1,
            ),
          ),
          oddsCard(46, 'Plus de 7', BetChoice.over, overOdds),
          oddsCard(178, 'Égal 7', BetChoice.equal, equalOdds),
          oddsCard(310, 'Moins de 7', BetChoice.under, underOdds),
          goldButton(19, 'MIN', onMin),
          goldButton(131, 'X2', onDouble),
          goldButton(243, 'X/2', onHalf),
          goldButton(355, 'MAX', onMax),
          Positioned(
            left: 17,
            top: 537,
            width: 168,
            height: 53,
            child: StakeBoxFace(text: '${stake.toStringAsFixed(0)} XAF'),
          ),
          actionTile(
            x: 53,
            width: 91,
            height: 90,
            kind: ActionTileKind.blue,
            icon: const CoinsIcon(),
            onTap: onWallet,
          ),
          actionTile(
            x: 174,
            width: 126,
            height: 103,
            kind: ActionTileKind.green,
            icon: const PlayIcon(),
            onTap: onPlay,
          ),
          actionTile(
            x: 329,
            width: 92,
            height: 90,
            kind: ActionTileKind.blue,
            icon: const SyncIcon(),
            onTap: onPredictor,
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class DiceVisualPreview extends StatelessWidget {
  const DiceVisualPreview({super.key, required this.rolling});

  final bool rolling;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF242130),
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedGameDie(value: 1, rolling: rolling, seed: 1),
          const SizedBox(width: 14),
          AnimatedGameDie(value: 6, rolling: rolling, seed: 2),
        ],
      ),
    ),
  );
}

/// Écran complet, sans état ni réseau, pour comparer le rendu à la capture de
/// référence dans les tests visuels.
@visibleForTesting
class GameScreenVisualPreview extends StatelessWidget {
  const GameScreenVisualPreview({
    super.key,
    this.left = 6,
    this.right = 1,
    this.choice,
    this.rolling = false,
    this.balance = 600356.04,
    this.stake = 400,
    this.resultPayout,
  });

  final int left;
  final int right;
  final BetChoice? choice;
  final bool rolling;
  final double balance;
  final double stake;
  final double? resultPayout;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBodyEdge,
    body: Column(
      children: [
        GameHeader(
          balance: balance,
          onAddCredits: () {},
          onProfileTap: () {},
          onBackTap: () {},
        ),
        Expanded(
          child: _GameBody(
            child: _GameCanvas(
              rolling: rolling,
              left: left,
              right: right,
              choice: choice,
              stake: stake,
              resultPayout: resultPayout,
              overOdds: 2.3,
              equalOdds: 5.8,
              underOdds: 2.3,
            ),
          ),
        ),
      ],
    ),
  );
}
