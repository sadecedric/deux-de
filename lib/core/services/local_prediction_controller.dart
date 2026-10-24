import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../features/game/models/bet_choice.dart';

class LocalPrediction {
  const LocalPrediction(this.dice1, this.dice2, {this.revision = 0});

  final int dice1;
  final int dice2;
  final int revision;

  factory LocalPrediction.fromJson(Map<String, dynamic> data) =>
      LocalPrediction(
        (data['dice_1'] as num).toInt(),
        (data['dice_2'] as num).toInt(),
        revision: (data['revision'] as num).toInt(),
      );

  BetChoice get result => dice1 + dice2 < 7
      ? BetChoice.under
      : dice1 + dice2 == 7
      ? BetChoice.equal
      : BetChoice.over;
}

abstract class PredictionStore {
  Future<LocalPrediction> read();
  Future<LocalPrediction> generate();
  Stream<LocalPrediction> watch();
}

/// Source partagée pour les comptes connectés ; génération locale en test.
class LocalPredictionController extends ChangeNotifier {
  LocalPredictionController({Random? random, this._store})
    : _random = random ?? Random() {
    _current = _generate();
  }

  final Random _random;
  final PredictionStore? _store;
  late LocalPrediction _current;
  StreamSubscription<LocalPrediction>? _subscription;
  Future<void>? _initialization;
  bool _disposed = false;
  bool _loaded = false;
  String? error;

  LocalPrediction get current => _current;
  bool get isReady => _store == null || _loaded;

  Future<void> initialize() {
    if (_disposed) return Future.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (_store == null) return;
    try {
      _apply(await _store.read());
      if (_disposed) return;
      _subscription = _store.watch().listen(
        _apply,
        onError: (Object _) {
          if (_disposed) return;
          final previous = _subscription;
          _subscription = null;
          unawaited(previous?.cancel());
          error = 'Synchronisation interrompue. Appuyez sur Prédire pour réessayer.';
          notifyListeners();
        },
      );
    } catch (_) {
      if (_disposed) return;
      error = 'Connexion au prédicteur impossible. Appuyez sur Prédire pour réessayer.';
      notifyListeners();
      _initialization = null;
    }
  }

  void _apply(LocalPrediction prediction) {
    if (_disposed || (_loaded && prediction.revision < _current.revision)) {
      return;
    }
    _current = prediction;
    _loaded = true;
    error = null;
    notifyListeners();
  }

  /// Produit une recommandation uniquement à la demande de l'utilisateur.
  Future<void> predict() async {
    if (_store == null) {
      _apply(_generate(revision: _current.revision + 1));
      return;
    }
    _apply(await _store.generate());
    if (_disposed) return;
    if (_subscription == null) {
      _initialization = null;
      await initialize();
    }
  }

  /// Relit le serveur avant la mise pour éviter un ancien résultat en cache.
  Future<LocalPrediction> forPlay() async {
    if (_store != null) _apply(await _store.read());
    return _current;
  }

  LocalPrediction _generate({int revision = 0}) => LocalPrediction(
    _random.nextInt(6) + 1,
    _random.nextInt(6) + 1,
    revision: revision,
  );

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
