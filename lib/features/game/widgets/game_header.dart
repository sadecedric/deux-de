import 'package:flutter/material.dart';

import 'game_art.dart';

/// En-tête de l'écran de jeu, reproduit d'après la capture de référence :
/// flèche retour, capsule du solde avec bouton « + » vert, badge bonus.
///
/// La barre bleue s'étend sous la barre d'état du téléphone. Le contenu est
/// dessiné sur une grille de 474 × 73 px mise à l'échelle de la largeur.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.balance,
    required this.onAddCredits,
    required this.onProfileTap,
    this.onBackTap,
  });

  final double balance;
  final VoidCallback onAddCredits;
  final VoidCallback onProfileTap;
  final VoidCallback? onBackTap;

  static const double _designHeight = 73;

  @override
  Widget build(BuildContext context) {
    final noScale = MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.noScaling);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: kHeaderBlue,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: MediaQuery(
          data: noScale,
          child: AspectRatio(
            aspectRatio: kDesignWidth / _designHeight,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: kDesignWidth,
                height: _designHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 10,
                      width: 78,
                      height: 54,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onBackTap,
                        child: const Align(
                          alignment: Alignment(-.33, .05),
                          child: BackArrowIcon(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 150,
                      top: 16,
                      width: 174,
                      height: 41,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16293A),
                          borderRadius: BorderRadius.circular(21),
                        ),
                      ),
                    ),
                    // Capsule plus sombre qui contient le solde.
                    Positioned(
                      left: 156,
                      top: 21,
                      width: 110,
                      height: 31,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1923),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 166,
                      top: 24,
                      width: 104,
                      height: 25,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${balance.toStringAsFixed(2)}₣',
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 277,
                      top: 21,
                      width: 42,
                      height: 31,
                      child: GestureDetector(
                        onTap: onAddCredits,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(9)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF5BC97E), Color(0xFF3FAE62)],
                            ),
                          ),
                          child: Center(child: HeaderPlusIcon()),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 426,
                      top: 21,
                      width: 40,
                      height: 38,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onProfileTap,
                        child: const BonusBadgeIcon(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
