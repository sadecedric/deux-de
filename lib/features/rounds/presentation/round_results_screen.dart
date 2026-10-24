import 'package:flutter/material.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/services/session_guard.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../game/models/bet_choice.dart';

/// Affiche uniquement le résultat réservé du prochain tour.
/// Le même résultat sera consommé par `play_round` lorsque le joueur jouera.
class RoundResultsScreen extends StatefulWidget {
  const RoundResultsScreen({super.key});

  @override
  State<RoundResultsScreen> createState() => _RoundResultsScreenState();
}

class _RoundResultsScreenState extends State<RoundResultsScreen> {
  _UpcomingRound? _round;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpcomingRound();
  }

  Future<void> _loadUpcomingRound() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await supabase.rpc('get_or_create_next_round');
      if (!mounted) return;
      setState(() {
        _round = _UpcomingRound.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        _loading = false;
      });
    } catch (error) {
      // Compte bloqué ou expiré : retour immédiat à l'écran de connexion.
      if (SessionGuard.handleAccessError(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const BackButton(),
      title: const Text('Résultat'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _loading ? null : _loadUpcomingRound,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : _round == null
              ? _ErrorCard(onRetry: _loadUpcomingRound, details: _error)
              : _RoundCard(round: _round!),
        ),
      ),
    ),
  );
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.round});

  final _UpcomingRound round;

  @override
  Widget build(BuildContext context) {
    final color = switch (round.result) {
      BetChoice.over => AppColors.greenBright,
      BetChoice.equal => AppColors.gold,
      BetChoice.under => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: color.withValues(alpha: .55), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .12), blurRadius: 24),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'RÉSULTAT',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimens.spaceL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Die(value: round.dice1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.spaceM),
                child: Icon(Icons.add_rounded, color: AppColors.textMuted),
              ),
              _Die(value: round.dice2),
            ],
          ),
          const SizedBox(height: AppDimens.spaceL),
          Text(
            'TOTAL : ${round.total}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDimens.spaceS),
          Text(
            round.result.label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Die extends StatelessWidget {
  const _Die({required this.value});
  final int value;

  static const pips = <int, List<Alignment>>{
    1: [Alignment.center],
    2: [Alignment.topLeft, Alignment.bottomRight],
    3: [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
    4: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    5: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    6: [
      Alignment.topLeft,
      Alignment.centerLeft,
      Alignment.bottomLeft,
      Alignment.topRight,
      Alignment.centerRight,
      Alignment.bottomRight,
    ],
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 100,
    height: 100,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
      ],
    ),
    child: Stack(
      children: [
        for (final alignment in pips[value]!)
          Align(
            alignment: alignment,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF20202A),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry, this.details});
  final VoidCallback onRetry;
  final String? details;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 54),
      const SizedBox(height: AppDimens.spaceM),
      const Text(
        'Impossible de charger le prochain résultat.',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      if (details != null) ...[
        const SizedBox(height: AppDimens.spaceS),
        Text(
          details!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
      const SizedBox(height: AppDimens.spaceM),
      ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
    ],
  );
}

class _UpcomingRound {
  const _UpcomingRound({
    required this.dice1,
    required this.dice2,
    required this.total,
    required this.result,
  });

  factory _UpcomingRound.fromJson(Map<String, dynamic> json) => _UpcomingRound(
    dice1: json['dice1'] as int,
    dice2: json['dice2'] as int,
    total: json['total'] as int,
    result: betChoiceFromServerCode(json['result'] as String),
  );

  final int dice1;
  final int dice2;
  final int total;
  final BetChoice result;
}
