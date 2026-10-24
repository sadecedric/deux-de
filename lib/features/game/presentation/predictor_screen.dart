import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/local_prediction_controller.dart';
import '../models/bet_choice.dart';
import '../../../core/theme/app_colors.dart';

class PredictorScreen extends StatefulWidget {
  const PredictorScreen({super.key, required this.controller, this.onSignOut});

  final LocalPredictionController controller;
  final VoidCallback? onSignOut;

  @override
  State<PredictorScreen> createState() => _PredictorScreenState();
}

class _PredictorScreenState extends State<PredictorScreen> {
  Timer? _preparationTimer;
  bool _loading = false;
  String? _requestError;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  void _predict() {
    if (_loading) return;
    setState(() {
      _loading = true;
      _requestError = null;
    });
    _preparationTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      try {
        await widget.controller.predict();
      } catch (_) {
        if (mounted) {
          setState(
            () => _requestError = 'Prédiction indisponible. Vérifiez votre connexion et réessayez.',
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _preparationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        if (widget.onSignOut != null)
          IconButton(
            onPressed: widget.onSignOut,
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout_rounded),
          ),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final prediction = widget.controller.current;
          final generation = prediction.revision;
          final symbol = !widget.controller.isReady
              ? '—'
              : switch (prediction.result) {
                  BetChoice.over => '> 7',
                  BetChoice.equal => '= 7',
                  BetChoice.under => '< 7',
                };
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PRÉDICTEUR',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.controller.isReady ? 'Voici ce qu’il faut jouer' : 'Appuyez sur Prédire pour préparer votre recommandation',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Semantics(
                      key: ValueKey('prediction-$generation'),
                      label: widget.controller.isReady
                          ? prediction.result.label
                          : 'Prédiction en attente',
                      excludeSemantics: true,
                      child: Text(
                        symbol,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 80,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: _loading
                          ? const Text(
                              'Préparation…',
                              key: ValueKey('preparing'),
                              style: TextStyle(color: AppColors.textSecondary),
                            )
                          : generation == 0
                          ? const SizedBox.shrink()
                          : Semantics(
                              key: ValueKey('ready-$generation'),
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.greenBright.withValues(
                                      alpha: .45,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: AppColors.greenBright,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Prédiction n°$generation prête',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.greenBright,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    height: 56,
                    child: FilledButton.icon(
                      key: const ValueKey('predict-button'),
                      onPressed: _loading ? null : _predict,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _loading ? 'Chargement…' : 'PRÉDIRE',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        disabledBackgroundColor: AppColors.green.withValues(
                          alpha: .6,
                        ),
                        disabledForegroundColor: Colors.white,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppColors.greenBright,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.greenBright,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_requestError != null ||
                      widget.controller.error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _requestError ?? widget.controller.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
