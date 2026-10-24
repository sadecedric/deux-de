import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Éléments graphiques de l'écran de jeu, dessinés d'après la capture de
/// référence (474 px de large). Toutes les dimensions ci-dessous sont
/// exprimées dans ce repère ; l'écran met l'ensemble à l'échelle de la largeur
/// du téléphone (voir `_GameCanvas`).
const double kDesignWidth = 474;

/// Hauteur utile du contenu (jusqu'au bas des boutons d'action). Le décor du
/// bas déborde volontairement : il est simplement rogné si l'écran est court.
const double kDesignBodyHeight = 735;

const Color kHeaderBlue = Color(0xFF2A4563);
const Color kBodyEdge = Color(0xFF262738);
const Color kBodyCenter = Color(0xFF333242);

const Color _kEdgeBlack = Color(0xFF100C0A);
const Color _kFieldBorder = Color(0xFF4C566C);
const Color _kPanelPlum = Color(0xFF231E29);

Paint _fill(Color color) => Paint()..color = color;

// ---------------------------------------------------------------------------
// Fond
// ---------------------------------------------------------------------------

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [kBodyEdge, kBodyCenter, kBodyEdge],
        stops: [0, .5, 1],
      ),
    ),
  );
}

/// Décor très discret : dés fantômes et grande forme sombre en bas.
class GameBackdropDecor extends StatelessWidget {
  const GameBackdropDecor({super.key});

  @override
  Widget build(BuildContext context) {
    Widget ghost(double left, double top, double size, int value) {
      return Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: Opacity(
          opacity: .055,
          child: CustomPaint(painter: IsoDiePainter(value, shine: 0)),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ghost(292, -30, 96, 4),
        ghost(78, 52, 46, 2),
        ghost(424, 428, 56, 5),
        ghost(4, 872, 84, 3),
        const Positioned(
          left: 120,
          top: 745,
          width: 280,
          height: 170,
          child: CustomPaint(painter: _DarkCheckPainter()),
        ),
      ],
    );
  }
}

class _DarkCheckPainter extends CustomPainter {
  const _DarkCheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xF0231D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    // Coordonnées du repère de jeu (origine de la zone de dessin : 120, 745).
    final path = Path()
      ..moveTo(190 - 120, 808 - 745)
      ..lineTo(252 - 120, 872 - 745)
      ..lineTo(348 - 120, 862 - 745);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Case « ? » et barres dorées croisées
// ---------------------------------------------------------------------------

class HelpBadge extends StatelessWidget {
  const HelpBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: const _HelpBadgePainter(),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.w800,
              height: 1,
              shadows: [Shadow(color: Color(0xAA7A4A08), offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HelpBadgePainter extends CustomPainter {
  const _HelpBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    void bar(double angle, double length, List<Color> colors) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: length,
        height: 33,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16.5));
      canvas.drawRRect(
        rrect.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(
        rrect,
        Paint()..shader = LinearGradient(colors: colors).createShader(rect),
      );
      canvas.restore();
    }

    bar(1.862, 160, const [Color(0xFFE8D293), Color(0xFF8C6B37)]);
    bar(0.518, 130, const [Color(0xFF8C6B37), Color(0xFFE8D293)]);

    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(13),
    );
    canvas.drawRRect(outer, _fill(_kEdgeBlack));
    final rim = outer.deflate(3);
    canvas.drawRRect(
      rim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEBDCA9), Color(0xFFB59355)],
        ).createShader(rim.outerRect),
    );
    final plate = outer.deflate(7);
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1D89B), Color(0xFFD8A044), Color(0xFFC07C22)],
        ).createShader(plate.outerRect),
    );
    canvas.drawRRect(
      plate.deflate(1),
      Paint()
        ..color = const Color(0x66A8690F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Bandeau d'invite
// ---------------------------------------------------------------------------

enum PromptBarTone { neutral, win, loss, error }

class PromptBar extends StatelessWidget {
  const PromptBar({
    super.key,
    required this.text,
    this.tone = PromptBarTone.neutral,
  });

  final String text;
  final PromptBarTone tone;

  @override
  Widget build(BuildContext context) {
    final won = tone == PromptBarTone.win;
    final lost = tone == PromptBarTone.loss;
    final error = tone == PromptBarTone.error;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: won || lost
            ? null
            : error
            ? const Color(0xFF4A2530)
            : const Color(0xFF362F3D),
        gradient: won
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3C4333),
                  Color(0xFF626B30),
                  Color(0xFF363A2A),
                ],
              )
            : lost
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF362632),
                  Color(0xFF422A37),
                  Color(0xFF29232F),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: won
              ? const Color(0xFFB7EC16)
              : lost
              ? const Color(0xFFFF0D68)
              : error
              ? const Color(0xFFE5484D)
              : _kFieldBorder,
          width: won || lost ? 2.5 : 2,
        ),
        boxShadow: won
            ? const [
                BoxShadow(
                  color: Color(0xA8A9E20D),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : lost
            ? const [
                BoxShadow(
                  color: Color(0x88FF0D68),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: lost ? const Color(0xFFFF2C73) : Colors.white,
          fontSize: lost ? 16 : 15,
          fontWeight: lost ? FontWeight.w500 : FontWeight.w700,
          height: won ? 1.0 : 1.15,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Médaillon des dés : anneau doré + double liseré noir
// ---------------------------------------------------------------------------

class MedallionPainter extends CustomPainter {
  const MedallionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 184);

    // Halo sombre autour de l'anneau.
    canvas.drawCircle(
      Offset.zero,
      94,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(Offset.zero, 91.5, _fill(const Color(0xFF0B0A0F)));

    // Anneau doré : clair sur les côtés, plus sombre en haut et en bas.
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: 86.5);
    canvas.drawCircle(
      Offset.zero,
      79.25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.5
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFDE09D),
            Color(0xFFAF8F56),
            Color(0xFF98763F),
            Color(0xFFAF8F56),
            Color(0xFFFDE09D),
            Color(0xFFAF9057),
            Color(0xFF94713D),
            Color(0xFFAF9057),
            Color(0xFFFDE09D),
          ],
          stops: [0, .125, .25, .375, .5, .625, .75, .875, 1],
        ).createShader(ringRect),
    );
    canvas.drawCircle(
      Offset.zero,
      85.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xE6FFEFB8),
    );
    canvas.drawCircle(
      Offset.zero,
      72.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xB36B4F1F),
    );

    // Liseré noir intérieur puis fond du médaillon.
    canvas.drawCircle(Offset.zero, 72, _fill(const Color(0xFF05020A)));
    canvas.drawCircle(
      Offset.zero,
      63,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF1C1322), Color(0xFF07040B)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 63)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Dé au repos : cube arrondi en vue isométrique (3 faces visibles)
// ---------------------------------------------------------------------------

class IsoDiePainter extends CustomPainter {
  const IsoDiePainter(this.value, {this.shine = .22});

  final int value;
  final double shine;

  /// Valeurs des faces de gauche et de droite pour la face du dessus [top]
  /// (deux faces adjacentes, jamais opposées).
  static (int left, int right) sideFaces(int top) {
    final rest = [
      for (var v = 1; v <= 6; v++)
        if (v != top && v != 7 - top) v,
    ];
    final a = rest[0];
    final b = rest.firstWhere((v) => v != a && v != 7 - a);
    return (b, a);
  }

  static const _layouts = <int, List<Offset>>{
    1: [Offset(.5, .5)],
    2: [Offset(.27, .27), Offset(.73, .73)],
    3: [Offset(.27, .27), Offset(.5, .5), Offset(.73, .73)],
    4: [Offset(.27, .27), Offset(.73, .27), Offset(.27, .73), Offset(.73, .73)],
    5: [
      Offset(.27, .27),
      Offset(.73, .27),
      Offset(.5, .5),
      Offset(.27, .73),
      Offset(.73, .73),
    ],
    6: [
      Offset(.27, .23),
      Offset(.73, .23),
      Offset(.27, .5),
      Offset(.73, .5),
      Offset(.27, .77),
      Offset(.73, .77),
    ],
  };

  void _pips(
    Canvas canvas,
    Offset origin,
    Offset a,
    Offset b,
    int faceValue, {
    required double pipWidth,
    required double pipHeight,
    bool transpose = false,
  }) {
    canvas.save();
    canvas.transform(
      Matrix4(
        a.dx,
        a.dy,
        0,
        0,
        b.dx,
        b.dy,
        0,
        0,
        0,
        0,
        1,
        0,
        origin.dx,
        origin.dy,
        0,
        1,
      ).storage,
    );
    for (final layout in _layouts[faceValue.clamp(1, 6)]!) {
      final uv = transpose ? Offset(layout.dy, layout.dx) : layout;
      canvas.drawOval(
        Rect.fromCenter(center: uv, width: pipWidth, height: pipHeight),
        _fill(const Color(0xFF0F0F12)),
      );
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Mesuré sur la capture : le dé est un disque d'environ 123 × 119 px,
    // légèrement sous le centre du médaillon.
    canvas.translate(size.width / 2, size.height / 2 + 2.5);
    canvas.scale(size.width / 126 * 1.025, size.width / 126 * 1.07);

    // Jonction des trois faces (mesurée : le reflet blanc part de y ≈ -19).
    const junction = Offset(0, -19);
    const upperLeft = Offset(-60, -33);
    const upperRight = Offset(60, -33);
    const bottom = Offset(0, 62);

    final silhouette = Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 120, height: 111));

    canvas.save();
    canvas.clipPath(silhouette);

    Path polygon(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    Paint gradient(Offset from, Offset to, Color a, Color b) =>
        Paint()..shader = ui.Gradient.linear(from, to, [a, b]);

    // Valeurs de gris mesurées sur la capture : dessus ~205, face gauche
    // presque uniforme ~180, face droite de 175 (centre) à 158 (bord).
    canvas.drawRect(
      const Rect.fromLTRB(-70, -70, 70, 70),
      _fill(const Color(0xFFB4B4B6)),
    );
    canvas.drawPath(
      polygon(const [
        Offset(-80, -38),
        junction,
        Offset(80, -38),
        Offset(80, -80),
        Offset(-80, -80),
      ]),
      gradient(
        const Offset(0, -6),
        const Offset(0, -56),
        const Color(0xFFD8D8D8),
        const Color(0xFFBBBBBD),
      ),
    );
    canvas.drawPath(
      polygon(const [
        Offset(-80, -38),
        junction,
        Offset(0, 80),
        Offset(-80, 80),
      ]),
      gradient(
        const Offset(-4, 0),
        const Offset(-60, 0),
        const Color(0xFFB8B8BA),
        const Color(0xFFB0B0B2),
      ),
    );
    canvas.drawPath(
      polygon(const [junction, Offset(80, -38), Offset(80, 80), Offset(0, 80)]),
      gradient(
        const Offset(4, 0),
        const Offset(60, 0),
        const Color(0xFFB0B0B2),
        const Color(0xFF9E9EA1),
      ),
    );
    // Légère ombre vers le bas du dé.
    canvas.drawRect(
      const Rect.fromLTRB(-70, -70, 70, 70),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, 60), [
          const Color(0x00000000),
          const Color(0x22000000),
        ]),
    );

    // Arêtes discrètes entre les faces.
    canvas.drawPath(
      Path()
        ..moveTo(upperLeft.dx, upperLeft.dy)
        ..lineTo(junction.dx, junction.dy)
        ..lineTo(upperRight.dx, upperRight.dy)
        ..moveTo(junction.dx, junction.dy)
        ..lineTo(bottom.dx, bottom.dy),
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );

    // Seul vrai reflet : petit triangle blanc à l'endroit où les trois faces se
    // rejoignent (mesuré : luminance 247 sur ~30 × 35 px).
    final glint = Path()
      ..moveTo(-18, -19)
      ..quadraticBezierTo(0, -25, 19, -19)
      ..lineTo(12, 10)
      ..quadraticBezierTo(6, 30, 2, 28)
      ..quadraticBezierTo(-6, 10, -18, -19)
      ..close();
    canvas.drawPath(
      glint,
      Paint()
        ..color = Colors.white.withValues(alpha: .93 + shine * .07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    canvas.restore();

    canvas.drawPath(
      silhouette,
      Paint()
        ..color = const Color(0x556F6D73)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final (leftValue, rightValue) = sideFaces(value.clamp(1, 6));
    // Dessus : bande plate près du bord supérieur (points aplatis).
    _pips(
      canvas,
      const Offset(-46, -47),
      const Offset(92, -4),
      const Offset(4, 24),
      value,
      pipWidth: .11,
      pipHeight: .17,
      transpose: true,
    );
    // Faces latérales : points allongés et inclinés.
    _pips(
      canvas,
      upperLeft,
      junction - upperLeft,
      const Offset(0, 81),
      leftValue,
      pipWidth: .09,
      pipHeight: .17,
    );
    _pips(
      canvas,
      junction,
      upperRight - junction,
      const Offset(0, 81),
      rightValue,
      pipWidth: .09,
      pipHeight: .17,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IsoDiePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.shine != shine;
}

// ---------------------------------------------------------------------------
// Cartes de cote
// ---------------------------------------------------------------------------

class OddsCardFace extends StatelessWidget {
  const OddsCardFace({
    super.key,
    required this.label,
    required this.odds,
    required this.selected,
  });

  final String label;
  final String odds;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _kPanelPlum,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: selected ? const Color(0xFFF4D375) : _kFieldBorder,
        width: 2,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 11,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFCFAC64),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              height: 1.15,
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 42,
          child: CustomPaint(
            size: const Size(23, 23),
            painter: _RadioRingPainter(selected),
          ),
        ),
        Positioned(
          left: 52,
          top: 40,
          child: Text(
            'x $odds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22.5,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.15,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RadioRingPainter extends CustomPainter {
  const _RadioRingPainter(this.selected);

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3DC9A), Color(0xFFB08E45)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .5,
      _fill(selected ? const Color(0xFFF4D375) : const Color(0xFF26282E)),
    );
    canvas.drawCircle(
      center,
      radius * .5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x99745A26),
    );
  }

  @override
  bool shouldRepaint(covariant _RadioRingPainter oldDelegate) =>
      oldDelegate.selected != selected;
}

// ---------------------------------------------------------------------------
// Boutons dorés (MIN, X2, X/2, MAX) et champ de mise
// ---------------------------------------------------------------------------

class GoldButtonFace extends StatelessWidget {
  const GoldButtonFace({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF13100F), width: 3),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF0DEB0),
          Color(0xFFCDB77F),
          Color(0xFFAA9058),
          Color(0xFF8F7444),
        ],
        stops: [0, .18, .55, 1],
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF2A2230),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    ),
  );
}

class StakeBoxFace extends StatelessWidget {
  const StakeBoxFace({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2.5),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0508),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEBD7A3), Color(0xFFB59355), Color(0xFF8D7040)],
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF241D2A),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF1A121E), width: 1.5),
        ),
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.7,
            height: 1.1,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Boutons d'action (portefeuille, jouer, réinitialiser)
// ---------------------------------------------------------------------------

enum ActionTileKind { blue, green }

class ActionTileFace extends StatelessWidget {
  const ActionTileFace({super.key, required this.kind, required this.icon});

  final ActionTileKind kind;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final green = kind == ActionTileKind.green;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: Color(0xFF040404), spreadRadius: 4.5, blurRadius: 1),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3C98D), Color(0xFFA5844A), Color(0xFFDCC088)],
        ),
        border: Border.all(color: const Color(0xFF7A5E2E), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.5),
        child: DecoratedBox(
          // Fin liseré sombre entre le cadre doré et la tuile colorée.
          decoration: BoxDecoration(
            color: green ? const Color(0xFF203810) : const Color(0xFF141F58),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: green
                      ? const Color(0xFF7DA13A)
                      : const Color(0xFF6C8AF0),
                  width: 2,
                ),
                gradient: RadialGradient(
                  center: const Alignment(0, -.05),
                  radius: .72,
                  colors: green
                      ? const [
                          Color(0xFFA8DA14),
                          Color(0xFF86B026),
                          Color(0xFF3F6A2E),
                        ]
                      : const [
                          Color(0xFF5C7BD8),
                          Color(0xFF4562BA),
                          Color(0xFF1E367C),
                        ],
                  stops: const [0, .55, 1],
                ),
              ),
              child: Center(child: Transform.scale(scale: 1.12, child: icon)),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayIcon extends StatelessWidget {
  const PlayIcon({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(32, 42), painter: _PlayPainter());
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(3, 3)
      ..lineTo(size.width - 3, size.height / 2)
      ..lineTo(3, size.height - 3)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, _fill(Colors.white));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CoinsIcon extends StatelessWidget {
  const CoinsIcon({super.key});

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -3),
    child: const CustomPaint(size: Size(42, 34), painter: _CoinsPainter()),
  );
}

class _CoinsPainter extends CustomPainter {
  const _CoinsPainter();

  void _stack(
    Canvas canvas,
    double cx,
    double bottom,
    double width,
    int coins,
  ) {
    const thickness = 6.4;
    final height = width * .42;
    for (var i = 0; i < coins; i++) {
      final cy = bottom - i * thickness;
      final body = Rect.fromCenter(
        center: Offset(cx, cy),
        width: width,
        height: height,
      );
      // Tranche du jeton puis face supérieure.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(body.left, cy - .5, width, thickness),
          const Radius.circular(3),
        ),
        _fill(const Color(0xFFE6ECFA)),
      );
      canvas.drawOval(body, _fill(Colors.white));
      canvas.drawOval(
        body,
        Paint()
          ..color = const Color(0x66294088)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _stack(canvas, 9.5, size.height - 6, 17, 3);
    _stack(canvas, 29.5, size.height - 3, 24, 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SyncIcon extends StatelessWidget {
  const SyncIcon({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(38, 38), painter: _SyncPainter());
}

class _SyncPainter extends CustomPainter {
  const _SyncPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = 12.8;
    final arc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.2
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Deux arcs de ~150° avec une pointe de flèche à chaque extrémité.
    for (final start in [pi * 1.06, pi * 0.06]) {
      canvas.drawArc(rect, start, pi * .78, false, arc);
      final tipAngle = start + pi * .78;
      final tip = center + Offset(cos(tipAngle), sin(tipAngle)) * radius;
      final tangent = Offset(-sin(tipAngle), cos(tipAngle));
      final normal = Offset(cos(tipAngle), sin(tipAngle));
      final head = Path()
        ..moveTo((tip + tangent * 9).dx, (tip + tangent * 9).dy)
        ..lineTo((tip + normal * 8.5).dx, (tip + normal * 8.5).dy)
        ..lineTo((tip - normal * 8.5).dx, (tip - normal * 8.5).dy)
        ..close();
      canvas.drawPath(head, _fill(Colors.white));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// En-tête : flèche retour et badge « bonus »
// ---------------------------------------------------------------------------

class BackArrowIcon extends StatelessWidget {
  const BackArrowIcon({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(28, 24), painter: _BackArrowPainter());
}

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA9B8C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(2, y), Offset(size.width - 2, y), paint);
    canvas.drawPath(
      Path()
        ..moveTo(12, y - 10)
        ..lineTo(2, y)
        ..lineTo(12, y + 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BonusBadgeIcon extends StatelessWidget {
  const BonusBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(36, 34), painter: _BonusBadgePainter());
}

class _BonusBadgePainter extends CustomPainter {
  const _BonusBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(15.5, 14.5);
    final dot = Paint()..color = const Color(0xCCA9B8C7);
    for (var i = 0; i < 24; i++) {
      final angle = i * pi * 2 / 24;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * 13.4,
        1.15,
        dot,
      );
    }
    // Mention « BONUS » presque illisible dans la capture : simple trait fin.
    canvas.drawLine(
      center.translate(-6.5, 0),
      center.translate(6.5, 0),
      Paint()
        ..color = const Color(0x88A9B8C7)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    const badge = Offset(26.5, 25.5);
    canvas.drawCircle(badge, 7, _fill(const Color(0xFF9FAEBC)));
    final plus = Paint()
      ..color = const Color(0xFF2A4563)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(badge.translate(-3, 0), badge.translate(3, 0), plus);
    canvas.drawLine(badge.translate(0, -3), badge.translate(0, 3), plus);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeaderPlusIcon extends StatelessWidget {
  const HeaderPlusIcon({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(20, 20), painter: _HeaderPlusPainter());
}

class _HeaderPlusPainter extends CustomPainter {
  const _HeaderPlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    canvas.drawLine(c.translate(-8, 0), c.translate(8, 0), paint);
    canvas.drawLine(c.translate(0, -8), c.translate(0, 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
