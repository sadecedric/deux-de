import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'game_art.dart';

// The reference clip shows about half a second of rotation, ending face-on.
const diceRollDuration = Duration(milliseconds: 560);
const diceIdleDuration = Duration(milliseconds: 3000);
const _idleFrameCount = 90;

class AnimatedGameDie extends StatefulWidget {
  const AnimatedGameDie({
    super.key,
    required this.value,
    required this.rolling,
    this.seed,
    this.initialFrontValue,
    this.initialTopValue,
  }) : assert(
         initialFrontValue == null ||
             (initialFrontValue >= 1 && initialFrontValue <= 6),
       ),
       assert(
         initialTopValue == null ||
             (initialTopValue >= 1 && initialTopValue <= 6),
       ),
       assert(
         initialFrontValue == null ||
             initialTopValue == null ||
             (initialFrontValue != initialTopValue &&
                 initialFrontValue + initialTopValue != 7),
       );

  final int? value;
  final bool rolling;
  final int? seed;
  final int? initialFrontValue;
  final int? initialTopValue;

  @override
  State<AnimatedGameDie> createState() => _AnimatedGameDieState();
}

class _AnimatedGameDieState extends State<AnimatedGameDie>
    with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _idleMotion;
  late final double _direction;
  late final int _initialFrontValue;
  late final int? _initialTopValue;

  @override
  void initState() {
    super.initState();
    final random = Random(widget.seed);
    _direction = random.nextBool() ? 1 : -1;
    _initialFrontValue = widget.initialFrontValue ?? random.nextInt(6) + 1;
    _initialTopValue = widget.initialTopValue;
    _motion = AnimationController(vsync: this, duration: diceRollDuration);
    _idleMotion = AnimationController(vsync: this, duration: diceIdleDuration);
    _syncIdleMotion();
    if (widget.rolling) _motion.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedGameDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) _motion.forward(from: 0);
    _syncIdleMotion();
  }

  void _syncIdleMotion() {
    if (widget.value == null && !widget.rolling) {
      if (!_idleMotion.isAnimating) _idleMotion.repeat();
    } else {
      _idleMotion.stop();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _idleMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 184,
    child: AnimatedBuilder(
      animation: Listenable.merge([_motion, _idleMotion]),
      builder: (context, _) {
        final t = _motion.value;
        // Spin the die, then blend into the brighter face-on result.
        final p = t < .72
            ? t / .86
            : (.72 + .28 * (1 - pow(1 - (t - .72) / .28, 2)) / 2) / .86;
        final moving = _motion.isAnimating;
        final idle = widget.value == null && !moving;
        final sprite = _initialFrontValue == 3 && _initialTopValue == 6
            ? 'left'
            : _initialFrontValue == 2 && _initialTopValue == 1
            ? 'right'
            : null;
        if (idle && sprite != null) {
          final frame =
              (_idleMotion.value * _idleFrameCount).floor() % _idleFrameCount;
          return ClipRect(
            child: Image.asset(
              'assets/dice/${sprite}_idle.webp',
              width: 184,
              height: 184,
              fit: BoxFit.none,
              alignment: Alignment(
                -1 + 2 * (frame % 10) / 9,
                -1 + 2 * (frame ~/ 10) / 8,
              ),
              filterQuality: FilterQuality.low,
              frameBuilder: (context, child, imageFrame, loaded) =>
                  loaded || imageFrame != null ? child : _openingFallback(),
            ),
          );
        }
        return CustomPaint(
          painter: const MedallionPainter(),
          child: Center(
            child: _paintDie(idle: idle, moving: moving, p: p),
          ),
        );
      },
    ),
  );

  Widget _openingFallback() => CustomPaint(
    painter: const MedallionPainter(),
    child: Center(
      child: CustomPaint(
        size: const Size.square(144),
        painter: _OpeningDiePainter(
          front: _initialFrontValue,
          top: _initialTopValue ?? 1,
          yaw: 0,
        ),
      ),
    ),
  );

  Widget _paintDie({
    required bool idle,
    required bool moving,
    required double p,
  }) {
    if (idle) {
      return CustomPaint(
        size: const Size.square(144),
        painter: _OpeningDiePainter(
          front: _initialFrontValue,
          top: _initialTopValue ?? 1,
          yaw: 0,
        ),
      );
    }
    final settled = CustomPaint(
      size: const Size.square(144),
      painter: _SettledDiePainter(widget.value ?? _initialFrontValue),
    );
    if (!moving) return settled;
    final tumbling = CustomPaint(
      size: const Size.square(144),
      painter: _RoundedDiePainter(
        value: widget.value ?? _initialFrontValue,
        rx: 4 * pi * p,
        ry: _direction * 2 * pi * p,
        rz: _direction * .65 * sin(3 * pi * p) * sin(pi * p),
      ),
    );
    final settleProgress = ((p - .84) / .16).clamp(0.0, 1.0);
    if (settleProgress == 0) return tumbling;
    if (settleProgress == 1) return settled;
    final opacity = Curves.easeOut.transform(settleProgress);
    return SizedBox.square(
      dimension: 144,
      child: Stack(
        children: [
          Opacity(opacity: 1 - opacity, child: tumbling),
          Opacity(opacity: opacity, child: settled),
        ],
      ),
    );
  }
}

/// Bright, face-on result shown after a throw. The darker rounded corners
/// suggest the curved body while the white face and larger pips stay legible.
class _SettledDiePainter extends CustomPainter {
  const _SettledDiePainter(this.value);

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 144);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-55, -55, 55, 55),
      const Radius.circular(23),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xB9000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD6D6D8), Color(0xFFAAAAAE), Color(0xFF595961)],
          stops: [0, .65, 1],
        ).createShader(const Rect.fromLTRB(-55, -55, 55, 55)),
    );

    final face = Path()
      ..moveTo(-30, -53)
      ..cubicTo(-45, -53, -52, -43, -53, -27)
      ..cubicTo(-55, -9, -55, 10, -52, 28)
      ..cubicTo(-49, 44, -39, 51, -20, 52)
      ..quadraticBezierTo(0, 54, 20, 52)
      ..cubicTo(39, 51, 49, 44, 52, 28)
      ..cubicTo(55, 10, 55, -9, 53, -27)
      ..cubicTo(52, -43, 45, -53, 30, -53)
      ..close();
    canvas.drawPath(
      face,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.12, -.16),
          radius: .73,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFEFEFE),
            Color(0xFFEAEAEC),
            Color(0xFFA9A9AE),
          ],
          stops: [0, .48, .82, 1],
        ).createShader(const Rect.fromLTRB(-52, -53, 52, 51)),
    );
    canvas.save();
    canvas.clipPath(face);
    canvas.drawRect(
      const Rect.fromLTRB(-55, -55, 55, 55),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x5585858B)],
          stops: [0, .73, 1],
        ).createShader(const Rect.fromLTRB(-55, -55, 55, 55)),
    );
    canvas.restore();

    for (final pip in _RoundedDiePainter._pips[value]!) {
      final center = Offset(pip.dx * 52, pip.dy * 56);
      canvas.drawCircle(
        center.translate(.5, 1),
        6.8,
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.3),
      );
      canvas.drawCircle(center, 6.3, Paint()..color = const Color(0xFF171719));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SettledDiePainter oldDelegate) =>
      value != oldDelegate.value;
}

/// The opening pose has a shallow, wide top and a rounded front. Drawing this
/// pose directly preserves the curved face boundary and the two satin glints
/// in the reference, which a uniformly lit cube mesh cannot reproduce.
class _OpeningDiePainter extends CustomPainter {
  const _OpeningDiePainter({
    required this.front,
    required this.top,
    required this.yaw,
  });

  final int front;
  final int top;
  final double yaw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 144);

    final body = Path()
      ..moveTo(-51, -40)
      ..cubicTo(-49, -53, -25, -58, 0, -58)
      ..cubicTo(25, -58, 47, -53, 51, -39)
      ..cubicTo(58, -14, 58, 23, 45, 45)
      ..cubicTo(35, 59, 17, 64, 0, 64)
      ..cubicTo(-17, 64, -35, 59, -45, 45)
      ..cubicTo(-54, 23, -56, -17, -51, -40)
      ..close();
    canvas.drawShadow(body, Colors.black, 2, false);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPaint(
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -28),
          const Offset(0, 64),
          [const Color(0xFFBDBDBF), const Color(0xFFB3B3B5)],
        ),
    );

    // Softly shaded flanks, leaving a broad, almost uniform front face.
    canvas.drawPaint(
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-56, 0),
          const Offset(56, 0),
          const [
            Color(0x4474747B),
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
            Color(0x3374747B),
          ],
          const [0, .17, .82, 1],
        ),
    );
    final cap = Path()
      ..moveTo(-51, -40)
      ..cubicTo(-49, -53, -25, -58, 0, -58)
      ..cubicTo(25, -58, 47, -53, 51, -39)
      ..cubicTo(51, -27, 26, -22, 0, -22)
      ..cubicTo(-26, -22, -51, -27, -51, -40)
      ..close();
    canvas.drawPath(
      cap,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -58),
          const Offset(0, -22),
          [const Color(0xFFBDBDBF), const Color(0xFFD3D3D4)],
        ),
    );

    // The visible flank grows as the front turns away. Its curved boundary
    // stays inside the same rounded silhouette throughout the oscillation.
    final turn = sin(yaw);
    final amount = turn.abs();
    final sideSign = turn >= 0 ? 1.0 : -1.0;
    final seam = sideSign * (54 - 77 * amount);
    if (amount > .001) {
      final flank = Path()
        ..moveTo(sideSign * 51, -39)
        ..quadraticBezierTo(sideSign * 35, -26, seam, -22)
        ..quadraticBezierTo(seam - sideSign * 3, 17, seam, 64)
        ..lineTo(sideSign * 65, 64)
        ..lineTo(sideSign * 65, -39)
        ..close();
      canvas.drawPath(
        flank,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(seam, 0),
            Offset(sideSign * 56, 0),
            [const Color(0xFFB6B6B8), const Color(0xFF939397)],
          ),
      );
    }

    final swivel = (amount / sin(.78)).clamp(0.0, 1.0);
    final highlightX = seam * swivel * (1 - swivel);
    final leftTip = Offset(-45, 1) * (1 - swivel) + Offset(seam, 56) * swivel;
    final rightTip = Offset(48, 7) * (1 - swivel) + Offset(seam, 56) * swivel;
    final leftGlint = Path()
      ..moveTo(-50, -35)
      ..quadraticBezierTo(-38, -22, highlightX - 8, -22)
      ..quadraticBezierTo(highlightX - 32, -18, leftTip.dx, leftTip.dy)
      ..quadraticBezierTo(-49, -13, -50, -35)
      ..close();
    final rightGlint = Path()
      ..moveTo(49, -34)
      ..quadraticBezierTo(36, -23, highlightX + 7, -22)
      ..quadraticBezierTo(highlightX + 30, -18, rightTip.dx, rightTip.dy)
      ..quadraticBezierTo(52, -14, 49, -34)
      ..close();
    for (final glint in [leftGlint, rightGlint]) {
      canvas.drawPath(
        glint,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -25),
            const Offset(0, 56),
            [
              const Color(0xBFFFFFFF),
              Color.lerp(
                const Color(0xBFFFFFFF),
                const Color(0x00FFFFFF),
                swivel,
              )!,
            ],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .8),
      );
    }
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0x555C5B65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );

    void pip(Offset center, double width, double height) {
      final bounds = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );
      canvas.drawOval(
        bounds.inflate(.55),
        Paint()
          ..color = const Color(0x80525254)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .6),
      );
      canvas.drawOval(bounds, Paint()..color = const Color(0xFF090D0C));
    }

    void topPip(Offset point) {
      final depth = (point.dy + 40) * 2.1;
      pip(
        Offset(
          point.dx * cos(yaw) - depth * turn,
          -40 + (point.dy + 40) * cos(yaw) + point.dx * turn * .22,
        ),
        9.5,
        3.3,
      );
    }

    void frontPip(Offset point) => pip(
      Offset(point.dx * cos(yaw) - 40 * turn, point.dy),
      10 * cos(yaw),
      9,
    );

    if (top == 6) {
      // Three columns and two rows, rather than the mesh's rotated layout.
      for (final point in const [
        Offset(-28, -48),
        Offset(-4, -49),
        Offset(19, -50),
        Offset(-26, -34),
        Offset(0, -35),
        Offset(26, -36),
      ]) {
        topPip(point);
      }
    } else {
      for (final point in _RoundedDiePainter._pips[top]!) {
        topPip(Offset(point.dx * 55, -43 + point.dy * 20));
      }
    }
    if (front == 2) {
      frontPip(const Offset(-20, 10));
      frontPip(const Offset(11, 38));
    } else if (front == 3) {
      frontPip(const Offset(22, 8));
      frontPip(const Offset(4, 25));
      frontPip(const Offset(-14, 41));
    } else {
      for (final point in _RoundedDiePainter._pips[front]!) {
        frontPip(Offset(point.dx * 48, 22 + point.dy * 44));
      }
    }
    if (amount > .08) {
      // Adjacent faces from the reference: 3/2/5 around the left die and
      // 4/2/3 around the right die. Opposite faces continue to add up to seven.
      final side = front == 3 ? (turn > 0 ? 2 : 5) : (turn > 0 ? 3 : 4);
      final flankWidth = (54 - seam.abs()).clamp(0.0, 54.0);
      for (final point in _RoundedDiePainter._pips[side]!) {
        final u = .5 + point.dx * .65;
        pip(
          Offset(seam + sideSign * flankWidth * u, 18 + point.dy * 53 - u * 8),
          (10 * amount).clamp(.5, 7.0),
          8,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OpeningDiePainter oldDelegate) =>
      front != oldDelegate.front ||
      top != oldDelegate.top ||
      yaw != oldDelegate.yaw;
}

class _V3 {
  const _V3(this.x, this.y, this.z);
  final double x, y, z;

  _V3 rotate(double rx, double ry, double rz) {
    final y1 = y * cos(rx) - z * sin(rx);
    final z1 = y * sin(rx) + z * cos(rx);
    final x2 = x * cos(ry) + z1 * sin(ry);
    return _V3(
      x2 * cos(rz) - y1 * sin(rz),
      x2 * sin(rz) + y1 * cos(rz),
      -x * sin(ry) + z1 * cos(ry),
    );
  }

  _V3 get normal {
    final length = sqrt(x * x + y * y + z * z);
    return _V3(x / length, y / length, z / length);
  }
}

class _SurfacePoint {
  const _SurfacePoint(this.position, this.normal);
  final _V3 position, normal;
}

class _RoundedDiePainter extends CustomPainter {
  const _RoundedDiePainter({
    required this.value,
    required this.rx,
    required this.ry,
    required this.rz,
  });
  final int value;
  final double rx, ry, rz;

  static const _pips = <int, List<Offset>>{
    1: [Offset.zero],
    2: [Offset(-.43, .43), Offset(.43, -.43)],
    3: [Offset(-.43, .43), Offset.zero, Offset(.43, -.43)],
    4: [
      Offset(-.43, -.43),
      Offset(.43, -.43),
      Offset(-.43, .43),
      Offset(.43, .43),
    ],
    5: [
      Offset(-.43, -.43),
      Offset(.43, -.43),
      Offset.zero,
      Offset(-.43, .43),
      Offset(.43, .43),
    ],
    6: [
      Offset(-.43, -.48),
      Offset(.43, -.48),
      Offset(-.43, 0),
      Offset(.43, 0),
      Offset(-.43, .48),
      Offset(.43, .48),
    ],
  };

  // A rounded cube surface, shared by the body and the pips. The points
  // belong to their faces throughout the rotation (no random face swapping).
  static _SurfacePoint _surface(int face, double u, double v) {
    final cube = switch (face) {
      0 => _V3(u, v, 1),
      1 => _V3(-u, v, -1),
      2 => _V3(1, v, -u),
      3 => _V3(-1, v, u),
      4 => _V3(u, -1, v),
      _ => _V3(u, 1, -v),
    };
    final scale =
        1 / pow(pow(cube.x, 4) + pow(cube.y, 4) + pow(cube.z, 4), .25);
    final p = _V3(cube.x * scale, cube.y * scale, cube.z * scale);
    return _SurfacePoint(
      p,
      _V3(
        pow(p.x, 3).toDouble(),
        pow(p.y, 3).toDouble(),
        pow(p.z, 3).toDouble(),
      ).normal,
    );
  }

  static final _mesh = List.generate(
    6,
    (face) => List.generate(
      17 * 17,
      (index) => _surface(face, (index % 17) / 8 - 1, (index ~/ 17) / 8 - 1),
    ),
  );

  Offset _project(_V3 p, Size size) =>
      Offset(size.width / 2 + p.x * 53, size.height / 2 + p.y * 53);

  Color _shade(_V3 n) {
    final light = max(0.0, -.35 * n.x - .80 * n.y + .48 * n.z);
    final highlight = pow(max(0.0, -.24 * n.x - .48 * n.y + .84 * n.z), 26) * 4;
    final tone = (154 + 90 * light + highlight).round().clamp(0, 255);
    return Color.fromARGB(255, tone, tone, tone);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <Offset>[];
    final colors = <Color>[];
    final indices = <int>[];
    for (final face in _mesh) {
      final base = positions.length;
      final normals = <_V3>[];
      for (final vertex in face) {
        final n = vertex.normal.rotate(rx, ry, rz);
        normals.add(n);
        positions.add(_project(vertex.position.rotate(rx, ry, rz), size));
        colors.add(_shade(n));
      }
      for (var row = 0; row < 16; row++) {
        for (var col = 0; col < 16; col++) {
          final a = row * 17 + col;
          final b = a + 1, c = a + 17, d = c + 1;
          if (normals[a].z + normals[b].z + normals[c].z + normals[d].z <= 0) {
            continue;
          }
          indices.addAll([
            base + a,
            base + b,
            base + c,
            base + b,
            base + d,
            base + c,
          ]);
        }
      }
    }
    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: indices,
      ),
      BlendMode.srcOver,
      Paint(),
    );

    // Opposite sides always add up to seven, for every possible final value.
    final top = _defaultTopFor(value);
    final side = [1, 2, 3, 4, 5, 6].firstWhere(
      (candidate) =>
          candidate != value &&
          candidate != 7 - value &&
          candidate != top &&
          candidate != 7 - top,
    );
    final faces = [value, 7 - value, side, 7 - side, top, 7 - top];
    for (var face = 0; face < 6; face++) {
      for (final pip in _pips[faces[face]]!) {
        final normal = _surface(face, pip.dx, pip.dy).normal.rotate(rx, ry, rz);
        if (normal.z <= .08) continue;
        final path = Path();
        for (var step = 0; step <= 20; step++) {
          final angle = 2 * pi * step / 20;
          final vertex = _surface(
            face,
            pip.dx + .092 * cos(angle),
            pip.dy + .092 * sin(angle),
          );
          final p = _project(vertex.position.rotate(rx, ry, rz), size);
          if (step == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(
          path..close(),
          Paint()..color = const Color(0xFF101010),
        );
      }
    }
  }

  static int _defaultTopFor(int front) {
    final remaining = [1, 2, 3, 4, 5, 6]
      ..remove(front)
      ..remove(7 - front);
    final side = remaining.first;
    return remaining.firstWhere((v) => v != side && v != 7 - side);
  }

  @override
  bool shouldRepaint(covariant _RoundedDiePainter old) =>
      old.value != value || old.rx != rx || old.ry != ry || old.rz != rz;
}
