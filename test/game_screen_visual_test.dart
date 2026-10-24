import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:under_over_7/features/game/presentation/game_screen.dart';
import 'package:under_over_7/features/game/widgets/animated_game_die.dart';

void main() {
  testWidgets('présentation initiale des dés de référence', (tester) async {
    tester.view.physicalSize = const Size(474, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: Color(0xFF30303F),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedGameDie(
                  value: null,
                  rolling: false,
                  initialFrontValue: 3,
                  initialTopValue: 6,
                ),
                SizedBox(width: 15),
                AnimatedGameDie(
                  value: null,
                  rolling: false,
                  initialFrontValue: 2,
                  initialTopValue: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final imageContext = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      await Future.wait([
        precacheImage(
          const AssetImage('assets/dice/left_idle.webp'),
          imageContext,
        ),
        precacheImage(
          const AssetImage('assets/dice/right_idle.webp'),
          imageContext,
        ),
      ]);
    });
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dice_opening.png'),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dice_opening_turn_right.png'),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dice_opening_turn_left.png'),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dice_opening.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('captures des phases de rotation 3D', (tester) async {
    tester.view.physicalSize = const Size(440, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> show({required bool rolling}) async {
      await tester.pumpWidget(
        MaterialApp(home: DiceVisualPreview(rolling: rolling)),
      );
      await tester.pump();
    }

    await show(rolling: false);
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_idle.png'),
    );

    await show(rolling: true);
    await tester.pump(const Duration(milliseconds: 80));
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_roll_1.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_roll_2.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_roll_3.png'),
    );

    await tester.pump(const Duration(milliseconds: 120));
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_settle_1.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_settle_2.png'),
    );
    await tester.pump(const Duration(milliseconds: 61));
    await show(rolling: false);
    await expectLater(
      find.byType(DiceVisualPreview),
      matchesGoldenFile('goldens/dice_settled.png'),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('bandeaux de gain et de perte dans le jeu', (tester) async {
    tester.view.physicalSize = const Size(474, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreenVisualPreview(left: 1, right: 6, resultPayout: 920),
      ),
    );
    await expectLater(
      find.byType(GameScreenVisualPreview),
      matchesGoldenFile('goldens/game_win.png'),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreenVisualPreview(left: 1, right: 6, resultPayout: 0),
      ),
    );
    await expectLater(
      find.byType(GameScreenVisualPreview),
      matchesGoldenFile('goldens/game_loss.png'),
    );
  });
}
