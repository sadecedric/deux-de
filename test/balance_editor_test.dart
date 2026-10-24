import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:under_over_7/core/services/wallet_controller.dart';
import 'package:under_over_7/features/wallet/widgets/balance_editor.dart';

void main() {
  test('solde indépendant et conservé pour chaque utilisateur', () async {
    SharedPreferences.setMockInitialValues({});
    final wallet = WalletController.instance;
    await wallet.loadForUser('balance-user-a');
    await wallet.setBalance(12345.67);
    await wallet.loadForUser('balance-user-b');
    await wallet.setBalance(0);
    expect(wallet.balance, 0);
    await wallet.loadForUser('balance-user-a');
    expect(wallet.balance, 12345.67);
    expect(wallet.placeBet(100), true);
    wallet.creditWin(230);
    await wallet.loadForUser('balance-user-b');
    expect(wallet.balance, 0);
    await wallet.loadForUser('balance-user-a');
    expect(wallet.balance, 12475.67);
    await expectLater(wallet.setBalance(double.nan), throwsArgumentError);
    await expectLater(wallet.setBalance(-1), throwsArgumentError);
  });

  testWidgets('saisie libre, virgule décimale et refus des soldes négatifs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await WalletController.instance.loadForUser('balance-editor');
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBalanceEditor(context),
              child: const Text('Modifier'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Saisissez un montant positif ou zéro.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '12 345,50');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(WalletController.instance.balance, 12345.5);
    expect(find.text('Modifier mon solde'), findsNothing);
  });
}
