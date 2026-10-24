import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:under_over_7/core/services/local_prediction_controller.dart';
import 'package:under_over_7/features/game/presentation/predictor_screen.dart';

class _RepeatedRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  testWidgets('le portail tient sur un petit téléphone et sur ordinateur', (
    tester,
  ) async {
    final controller = LocalPredictionController(random: _RepeatedRandom());
    addTearDown(controller.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: PredictorScreen(controller: controller, onSignOut: () {}),
        ),
      );
      await controller.predict();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Se déconnecter'), findsOneWidget);
      expect(find.byKey(const ValueKey('predict-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'trois recommandations identiques ont chacune leur confirmation',
    (tester) async {
      final controller = LocalPredictionController(random: _RepeatedRandom());
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await tester.pumpWidget(
        MaterialApp(home: PredictorScreen(controller: controller)),
      );

      for (var generation = 1; generation <= 3; generation++) {
        await tester.tap(find.byKey(const ValueKey('predict-button')));
        await tester.pump();
        expect(find.text('Chargement…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('predict-button')),
              )
              .onPressed,
          isNull,
        );
        expect(notifications, generation - 1);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(notifications, generation);
        expect(find.text('< 7'), findsOneWidget);
        expect(find.text('Prédiction n°$generation prête'), findsOneWidget);
        expect(find.byKey(ValueKey('prediction-$generation')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('PRÉDIRE'), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('predict-button')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(notifications, 3);
      expect(tester.takeException(), isNull);
    },
  );
}
