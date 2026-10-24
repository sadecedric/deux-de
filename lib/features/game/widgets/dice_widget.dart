import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Dé virtuel avec relief 3D, encadré d'un cercle doré.
///
/// Tant que [isAnimating] est vrai, le dé défile rapidement à travers des
/// faces aléatoires puis ralentit progressivement (impression de lancer).
/// Lorsque [isAnimating] repasse à faux, il se stabilise sur [value] avec un
/// léger rebond d'atterrissage.
class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.value,
    this.isAnimating = false,
    this.size = 84,
  });

  final int value;
  final bool isAnimating;
  final double size;

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  final Random _random = Random();

  late final AnimationController _settleController;
  late final Animation<double> _settleScale;

  late final AnimationController _wobbleController;
  late final Animation<double> _wobbleAngle;

  Timer? _cycleTimer;
  int _cycleStepMs = 55;
  int _displayValue = 1;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;

    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1,
    );
    _settleScale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.elasticOut),
    );

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _wobbleAngle = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    if (widget.isAnimating) _startRolling();
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startRolling();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _stopRollingAndSettle();
    }
  }

  void _startRolling() {
    _cycleStepMs = 55;
    _wobbleController.repeat(reverse: true);
    _scheduleNextFace();
  }

  void _scheduleNextFace() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer(Duration(milliseconds: _cycleStepMs), () {
      if (!mounted || !widget.isAnimating) return;
      setState(() => _displayValue = _random.nextInt(6) + 1);
      _cycleStepMs = (_cycleStepMs * 1.16).clamp(55, 260).round();
      _scheduleNextFace();
    });
  }

  void _stopRollingAndSettle() {
    _cycleTimer?.cancel();
    _wobbleController.stop();
    _wobbleController.value = 0;
    setState(() => _displayValue = widget.value);
    _settleController.forward(from: 0);
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _settleController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceSize = widget.size * 0.72;

    return AnimatedBuilder(
      animation: Listenable.merge([_settleController, _wobbleController]),
      builder: (context, child) {
        final scale = widget.isAnimating ? 1.0 : _settleScale.value;
        final angle = widget.isAnimating ? _wobbleAngle.value : 0.0;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gold, AppColors.goldDim],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: faceSize,
          height: faceSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(faceSize * 0.22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDFDFD), Color(0xFFD9DCE6)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(faceSize * 0.14),
          child: _DiceFace(value: _displayValue),
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value});

  final int value;

  static const Map<int, List<Alignment>> _pipLayout = {
    1: [Alignment.center],
    2: [Alignment.topLeft, Alignment.bottomRight],
    3: [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
    4: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    5: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    6: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _pipLayout[value.clamp(1, 6)] ?? _pipLayout[1]!;

    return Stack(
      children: pips
          .map(
            (alignment) => Align(
              alignment: alignment,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
