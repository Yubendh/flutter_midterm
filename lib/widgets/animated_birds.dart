import 'dart:math' as math;

import 'package:flutter/material.dart';

const int _birdLoopSeconds = 70;               // lower = faster
const double _bird1SizeFactor = 0.18;          // size as fraction of screen width
const double _bird2SizeFactor = 0.14;
const double _bird1BaseTop = 82.0;             // vertical position in pixels
const double _bird2BaseTop = 154.0;
const double _birdOpacity = 0.95;              // 0.0 = invisible, 1.0 = solid
const String _birdImagePath = 'assets/images/birds.png';

class AnimatedBirdsWidget extends StatefulWidget {
  const AnimatedBirdsWidget({super.key});

  @override
  State<AnimatedBirdsWidget> createState() => _AnimatedBirdsWidgetState();
}

class _AnimatedBirdsWidgetState extends State<AnimatedBirdsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controllerBirds;

  @override
  void initState() {
    super.initState();
    _controllerBirds = AnimationController(
      duration: Duration(seconds: _birdLoopSeconds),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controllerBirds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double birdSize = (screenSize.width * _bird1SizeFactor).clamp(48.0, 86.0);
    final double smallBirdSize = (screenSize.width * _bird2SizeFactor).clamp(40.0, 70.0);

    return AnimatedBuilder(
      animation: _controllerBirds,
      builder: (context, _) {
        final double travelDistance = screenSize.width + 900;
        final double progress = _controllerBirds.value;

        // Offset bird 2 by 58 % so both birds are never at the same x position.
        final double bird1Left = (progress * travelDistance) % travelDistance - 180;
        final double bird2Left = (progress * travelDistance + travelDistance * 0.58) % travelDistance - 180;

        // Sine wave gives each bird a gentle vertical bob.
        final double bird1Top = _bird1BaseTop + math.sin(progress * 2 * math.pi + 0.5) * 12;
        final double bird2Top = _bird2BaseTop + math.sin(progress * 2 * math.pi + 2.4) * 10;

        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned(left: bird1Left, top: bird1Top,
                  child: _BirdIcon(size: birdSize)),
              Positioned(left: bird2Left, top: bird2Top,
                  child: _BirdIcon(size: smallBirdSize)),
            ],
          ),
        );
      },
    );
  }
}

class _BirdIcon extends StatelessWidget {
  const _BirdIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _birdOpacity,
      child: SizedBox(
        width: size,
        height: size * 0.6, // image aspect ratio
        child: Image.asset(_birdImagePath, fit: BoxFit.contain),
      ),
    );
  }
}
