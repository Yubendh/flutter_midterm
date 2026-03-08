import 'dart:math' as math;

import 'package:flutter/material.dart';

const int _cloudLoopSeconds = 30;              // lower = faster
const double _cloud1SizeFactor = 0.26;         // size as fraction of screen width
const double _cloud2SizeFactor = 0.20;
const double _cloud3SizeFactor = 0.18;
const double _cloud1BaseTop = 45.0;            // vertical position in pixels
const double _cloud2BaseTop = 120.0;
const double _cloud3BaseTop = 190.0;
const double _cloudOpacity = 0.92;             // 0.0 = invisible, 1.0 = solid
const String _cloudImagePath = 'assets/images/cloud.png';

class AnimatedCloudsWidget extends StatefulWidget {
  const AnimatedCloudsWidget({super.key});

  @override
  State<AnimatedCloudsWidget> createState() => _AnimatedCloudsWidgetState();
}

class _AnimatedCloudsWidgetState extends State<AnimatedCloudsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controllerClouds;

  @override
  void initState() {
    super.initState();
    _controllerClouds = AnimationController(
      duration: Duration(seconds: _cloudLoopSeconds),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controllerClouds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double normalCloudSize = (screenSize.width * _cloud1SizeFactor).clamp(70.0, 110.0);
    final double smallCloudSize1 = (screenSize.width * _cloud2SizeFactor).clamp(55.0, 85.0);
    final double smallCloudSize2 = (screenSize.width * _cloud3SizeFactor).clamp(50.0, 80.0);

    return AnimatedBuilder(
      animation: _controllerClouds,
      builder: (context, _) {
        final double travelDistance = screenSize.width + 260;
        final double progress = _controllerClouds.value;

        // Spread clouds evenly by staggering their starting offsets.
        final double cloud1Left = (progress * travelDistance) % travelDistance - 130;
        final double cloud2Left = (progress * travelDistance + travelDistance / 3) % travelDistance - 130;
        final double cloud3Left = (progress * travelDistance + travelDistance * 2 / 3) % travelDistance - 130;

        // Sine wave gives each cloud a gentle vertical bob.
        final double cloud1Top = _cloud1BaseTop + math.sin(progress * 2 * math.pi + 0.0) * 8;
        final double cloud2Top = _cloud2BaseTop + math.sin(progress * 2 * math.pi + 1.6) * 10;
        final double cloud3Top = _cloud3BaseTop + math.sin(progress * 2 * math.pi + 3.2) * 7;

        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned(left: cloud1Left, top: cloud1Top,
                  child: _CloudIcon(size: normalCloudSize)),
              Positioned(left: cloud2Left, top: cloud2Top,
                  child: _CloudIcon(size: smallCloudSize1)),
              Positioned(left: cloud3Left, top: cloud3Top,
                  child: _CloudIcon(size: smallCloudSize2)),
            ],
          ),
        );
      },
    );
  }
}

class _CloudIcon extends StatelessWidget {
  const _CloudIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _cloudOpacity,
      child: SizedBox(
        width: size,
        height: size * 0.62, // image aspect ratio
        child: Image.asset(_cloudImagePath, fit: BoxFit.contain),
      ),
    );
  }
}
