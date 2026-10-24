import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:under_over_7/core/services/local_prediction_controller.dart';

/// Simule la source commune à deux appareils, sans réseau ni compte réel.
class _SharedStore implements PredictionStore {
  final changes = StreamController<LocalPrediction>.broadcast(sync: true);
  LocalPrediction current = const LocalPrediction(1, 1);
  bool offline = false;
  Completer<LocalPrediction>? pendingRead;

  @override
  Future<LocalPrediction> read() async {
    if (offline) throw StateError('offline');
    if (pendingRead != null) return pendingRead!.future;
    return current;
  }

  @override
  Future<LocalPrediction> generate() async {
    if (offline) throw StateError('offline');
    current = LocalPrediction(1, 1, revision: current.revision + 1);
    changes.add(current);
    return current;
  }

  @override
  Stream<LocalPrediction> watch() => changes.stream;
}

void main() {
  test(
    'site et application partagent le résultat et le numéro, même identiques',
    () async {
      final store = _SharedStore();
      final app = LocalPredictionController(store: store);
      final web = LocalPredictionController(store: store);
      addTearDown(() async {
        app.dispose();
        web.dispose();
        await store.changes.close();
      });

      expect(app.isReady, isFalse);
      await Future.wait([app.initialize(), web.initialize()]);
      for (var revision = 1; revision <= 3; revision++) {
        await web.predict();
        expect(app.current.revision, revision);
        expect(web.current.revision, revision);
        expect(app.current.result, web.current.result);
        expect((await app.forPlay()).revision, revision);
      }

      // Une réponse ancienne arrivée après la notification ne doit pas revenir en arrière.
      store.changes.add(const LocalPrediction(6, 6, revision: 1));
      expect(app.current.revision, 3);
      expect(app.current.dice1, 1);

      final reopened = LocalPredictionController(store: store);
      await reopened.initialize();
      expect(reopened.current.revision, 3);
      reopened.dispose();

      await app.predict();
      expect(web.current.revision, 4);
    },
  );

  test(
    'une panne réseau ne produit pas de résultat local et permet de réessayer',
    () async {
      final store = _SharedStore()..offline = true;
      final controller = LocalPredictionController(store: store);
      addTearDown(() async {
        controller.dispose();
        await store.changes.close();
      });
      await controller.initialize();
      expect(controller.isReady, isFalse);
      expect(controller.error, isNotNull);
      await expectLater(controller.predict(), throwsStateError);
      await expectLater(controller.forPlay(), throwsStateError);
      expect(controller.current.revision, 0);

      store.offline = false;
      await controller.predict();
      expect(controller.isReady, isTrue);
      expect(controller.error, isNull);
      expect(controller.current.revision, 1);
    },
  );

  test(
    'fermer un écran pendant la synchronisation ne laisse aucun abonnement',
    () async {
      final store = _SharedStore()..pendingRead = Completer<LocalPrediction>();
      final controller = LocalPredictionController(store: store);
      final request = controller.initialize();
      controller.dispose();
      store.pendingRead!.complete(store.current);
      await request;
      expect(store.changes.hasListener, isFalse);
      await store.changes.close();
    },
  );
}
