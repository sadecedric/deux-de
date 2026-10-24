import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:under_over_7/core/services/local_prediction_controller.dart';
import 'package:under_over_7/features/game/models/bet_choice.dart';
import 'package:under_over_7/features/game/presentation/game_screen.dart';
import 'package:under_over_7/features/auth/presentation/login_screen.dart';
import 'package:under_over_7/features/game/presentation/predictor_screen.dart';
import 'package:under_over_7/features/game/widgets/game_art.dart';
import 'package:under_over_7/core/services/game_history_controller.dart';
import 'package:under_over_7/core/services/wallet_controller.dart';
import 'package:under_over_7/main.dart';

void main() {
  test('la prédiction change uniquement lorsque le bouton est utilisé', () {
    final controller = LocalPredictionController(random: Random(3));
    addTearDown(controller.dispose);
    final initial = controller.current;
    var notifications = 0;
    controller.addListener(() => notifications++);

    expect(controller.current, same(initial));
    controller.predict();
    expect(controller.current, isNot(same(initial)));
    expect(notifications, 1);
    expect(controller.current.dice1, inInclusiveRange(1, 6));
    expect(controller.current.dice2, inInclusiveRange(1, 6));
  });

  testWidgets('la connexion est obligatoire au démarrage', (tester) async {
    await tester.pumpWidget(const UnderOver7App());
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('prediction stable jusqu’à une nouvelle demande', () {
    final controller = LocalPredictionController(random: Random(3));
    addTearDown(controller.dispose);
    final initial = controller.current;
    expect(controller.current, same(initial));
    controller.predict();
    expect(controller.current, isNot(same(initial)));
    expect(initial.dice1, inInclusiveRange(1, 6));
    expect(initial.dice2, inInclusiveRange(1, 6));
  });

  testWidgets('bouton bleu, prediction, gain et perte sans serveur', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.tap(find.byType(SyncIcon));
    await tester.pumpAndSettle();
    final page = tester.widget<PredictorScreen>(find.byType(PredictorScreen));
    expect(find.byKey(const ValueKey('predict-button')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byKey(const ValueKey('predict-button')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    final predicted = page.controller.current;
    final symbol = switch (predicted.result) {
      BetChoice.over => '> 7',
      BetChoice.equal => '= 7',
      BetChoice.under => '< 7',
    };
    expect(find.text(symbol), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    // The dice now oscillate continuously while awaiting the first bet.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    String label(BetChoice choice) => switch (choice) {
      BetChoice.over => 'Plus de 7',
      BetChoice.equal => 'Égal 7',
      BetChoice.under => 'Moins de 7',
    };
    final before = WalletController.instance.balance;
    await tester.tap(find.text(label(predicted.result)));
    await tester.tap(find.byType(PlayIcon));
    await tester.pump(const Duration(milliseconds: 561));
    final win = GameHistoryController.instance.entries.first;
    expect(win.dice1, predicted.dice1);
    expect(win.dice2, predicted.dice2);
    expect(win.payout, greaterThan(0));
    expect(WalletController.instance.balance, before - win.stake + win.payout);
    expect(
      find.text('VOUS AVEZ GAGNÉ :\n${win.payout.toStringAsFixed(0)} XAF'),
      findsOneWidget,
    );
    expect(
      tester.widget<PromptBar>(find.byType(PromptBar)).tone,
      PromptBarTone.win,
    );
    await tester.pump(const Duration(milliseconds: 3900));
    expect(
      find.text('VOUS AVEZ GAGNÉ :\n${win.payout.toStringAsFixed(0)} XAF'),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text('Placez un pari'), findsOneWidget);

    final current = page.controller.current;
    final wrong = BetChoice.values.firstWhere((c) => c != current.result);
    await tester.tap(find.text(label(wrong)));
    await tester.tap(find.byType(PlayIcon));
    await tester.pump(const Duration(milliseconds: 561));
    expect(GameHistoryController.instance.entries.first.payout, 0);
    expect(find.text('Pas de chance'), findsOneWidget);
    expect(
      tester.widget<PromptBar>(find.byType(PromptBar)).tone,
      PromptBarTone.loss,
    );
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.text('Pas de chance'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text('Placez un pari'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
