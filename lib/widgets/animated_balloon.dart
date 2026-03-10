import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

const double _driftRotationAmplitude = 0.05;  
const double _driftRotationCycles = 2.0;       

class AnimatedBalloonWidget extends StatelessWidget {
  const AnimatedBalloonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          _BalloonActor(
            spec: BalloonSpec(
              laneX: 0.22,
              sizeFactor: 0.35,
              growSeconds: 4,
              riseSeconds: 6,
              floatAwaySeconds: 3,
              topBounceSeconds: 0.6,
              mode: BalloonMode.floatAway,
              floatDriftX: -0.10,
              phaseOffset: 0.0,
              shadowOffset: const Offset(6, 8),
              shadowBlurRadius: 8.0,
              shadowColor: const Color(0x55000000),
              gradientColors: const [Colors.white, Color(0xFFCC0000)],
            ),
          ),
          _BalloonActor(
            spec: BalloonSpec(
              laneX: 0.50,
              sizeFactor: 0.50,
              growSeconds: 4,
              riseSeconds: 6,
              floatAwaySeconds: 3.5,
              topBounceSeconds: 0.6,
              mode: BalloonMode.floatAway,
              floatDriftX: 0.00,
              phaseOffset: 1.4,
              shadowOffset: const Offset(6, 8),
              shadowBlurRadius: 8.0,
              shadowColor: const Color(0x55000000),
              gradientColors: const [Colors.white, Color(0xFF1565C0)],
            ),
          ),
          _BalloonActor(
            spec: BalloonSpec(
              laneX: 0.78,
              sizeFactor: 0.18,
              growSeconds: 4,
              riseSeconds: 5,
              floatAwaySeconds: 3,
              topBounceSeconds: 0.7,
              mode: BalloonMode.topBounce,
              floatDriftX: 0.12,
              phaseOffset: 2.8,
              shadowOffset: const Offset(6, 8),
              shadowBlurRadius: 8.0,
              shadowColor: const Color(0x55000000),
              gradientColors: const [Colors.white, Color(0xFF2E7D32)],
            ),
          ),
        ],
      ),
    );
  }
}

enum BalloonMode {
  topBounce,
  floatAway,
}

class BalloonSpec {
  const BalloonSpec({
    required this.laneX,
    required this.sizeFactor,
    required this.growSeconds,
    required this.riseSeconds,
    required this.floatAwaySeconds,
    required this.topBounceSeconds,
    required this.mode,
    required this.floatDriftX,
    required this.phaseOffset,
    this.shadowOffset = const Offset(4, 6),
    this.shadowBlurRadius = 6.0,
    this.shadowColor = const Color(0x55000000),
    this.gradientColors,
  });

  final double laneX;
  final double sizeFactor;
  final double growSeconds;
  final double riseSeconds;
  final double floatAwaySeconds;
  final double topBounceSeconds;
  final BalloonMode mode;
  final double floatDriftX;
  final double phaseOffset;
  final Offset shadowOffset;
  final double shadowBlurRadius;
  final Color shadowColor;
  final List<Color>? gradientColors;
}

class _BalloonActor extends StatefulWidget {
  const _BalloonActor({required this.spec});

  final BalloonSpec spec;

  @override
  State<_BalloonActor> createState() => _BalloonActorState();
}

class _BalloonActorState extends State<_BalloonActor>
    with TickerProviderStateMixin {
  late final AnimationController _controllerPath;
  late final AnimationController _controllerGrowSize;
  late final AnimationController _controllerPulse;
  late final AnimationController _controllerTopBounce;
  late final Animation<double> _animationGrowProgress;
  late final Animation<double> _animationPulse;
  late final AudioPlayer _sfxPlayer;

  bool _isDragging = false;
  bool _pathWasAnimating = false;
  bool _growWasAnimating = false;
  bool _pathWasForward = true;
  bool _growWasForward = true;

  Offset _manualOffset = Offset.zero;
  Offset _driftOffset = Offset.zero;
  double _interactionTilt = 0.0;

  static const double _minBalloonWidth = 80.0;

  @override
  void initState() {
    super.initState();
    _sfxPlayer = AudioPlayer();
    _configureSfx();

    final double pathSeconds = widget.spec.mode == BalloonMode.floatAway
        ? widget.spec.riseSeconds + widget.spec.floatAwaySeconds
        : widget.spec.riseSeconds;

    _controllerPath = AnimationController(
      duration: Duration(milliseconds: (pathSeconds * 1000).round()),
      vsync: this,
    );
    _controllerGrowSize = AnimationController(
      duration: Duration(milliseconds: (widget.spec.growSeconds * 1000).round()),
      vsync: this,
    );
    _controllerPulse = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _controllerTopBounce = AnimationController(
      duration: Duration(milliseconds: (widget.spec.topBounceSeconds * 1000).round()),
      vsync: this,
    );

    _animationGrowProgress = CurvedAnimation(
      parent: _controllerGrowSize,
      curve: Curves.elasticInOut,
      reverseCurve: Curves.easeInOut,
    );
    _animationPulse = Tween<double>(begin: 0.9850, end: 1.005).animate(
      CurvedAnimation(parent: _controllerPulse, curve: Curves.easeInOut),
    );

    _controllerPath.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.spec.mode == BalloonMode.topBounce &&
          !_isDragging) {
        _controllerTopBounce
          ..reset()
          ..forward();
      }
      if (status == AnimationStatus.completed &&
          widget.spec.mode == BalloonMode.floatAway &&
          !_isDragging) {
        _controllerPath.reverse();
        _controllerGrowSize.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _manualOffset = Offset.zero;
          });
        }
      }
    });
  }

  Future<void> _configureSfx() async {
    await _sfxPlayer.setVolume(0.8);
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    _controllerPath.dispose();
    _controllerGrowSize.dispose();
    _controllerPulse.dispose();
    _controllerTopBounce.dispose();
    super.dispose();
  }

  Future<void> _toggleInflateDeflate() async {
    final bool isExpanded = _controllerPath.value >= 0.999 ||
        _controllerPath.status == AnimationStatus.completed;

    if (isExpanded) {
      await _sfxPlayer.play(AssetSource('audio/deflate.mp3'));
      _controllerTopBounce.stop();
      _controllerPath.reverse();
      _controllerGrowSize.reverse();
    } else {
      await _sfxPlayer.play(AssetSource('audio/inflate.mp3'));
      _controllerPath.forward();
      _controllerGrowSize.forward();
    }
  }

  void _pauseForDrag() {
    _pathWasAnimating = _controllerPath.isAnimating;
    _growWasAnimating = _controllerGrowSize.isAnimating;
    _pathWasForward = _controllerPath.status != AnimationStatus.reverse;
    _growWasForward = _controllerGrowSize.status != AnimationStatus.reverse;

    _controllerPath.stop(canceled: false);
    _controllerGrowSize.stop(canceled: false);
    _controllerTopBounce.stop(canceled: false);
  }

  void _resumeAfterDrag() {
    if (!mounted) {
      return;
    }
    if (_pathWasAnimating) {
      if (_pathWasForward) {
        _controllerPath.forward(from: _controllerPath.value);
      } else {
        _controllerPath.reverse(from: _controllerPath.value);
      }
    }
    if (_growWasAnimating) {
      if (_growWasForward) {
        _controllerGrowSize.forward(from: _controllerGrowSize.value);
      } else {
        _controllerGrowSize.reverse(from: _controllerGrowSize.value);
      }
    }
  }

  void _endDragAndResume() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isDragging = false;
      _driftOffset = Offset.zero;
      _interactionTilt = 0.0;
    });
    _resumeAfterDrag();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final double fullWidth =
        (screenSize.width * widget.spec.sizeFactor).clamp(64.0, 180.0).toDouble();
    final double balloonHeight = fullWidth * 1.35;
    final double startY = screenSize.height - balloonHeight - 72 - viewPaddingBottom;
    final double topY = (screenSize.height * 0.06).clamp(8.0, 80.0).toDouble();
    final double offscreenY = -balloonHeight * 1.25;
    final double laneLeft = (screenSize.width * widget.spec.laneX) - (fullWidth / 2);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _controllerPath,
        _animationGrowProgress,
        _animationPulse,
        _controllerTopBounce,
      ]),
      builder: (context, _) {
        final double p = _controllerPath.value.clamp(0.0, 1.0).toDouble();
        final double growP = _animationGrowProgress.value.clamp(0.0, 1.0).toDouble();
        final double balloonWidth = _lerp(_minBalloonWidth, fullWidth, growP);
        double x = laneLeft;
        double y = startY;

        if (widget.spec.mode == BalloonMode.topBounce) {
          y = _lerp(startY, topY, Curves.fastOutSlowIn.transform(p));
        } else {
          final double riseRatio = widget.spec.riseSeconds /
              (widget.spec.riseSeconds + widget.spec.floatAwaySeconds);
          if (p <= riseRatio) {
            final double riseP = (p / riseRatio).clamp(0.0, 1.0).toDouble();
            y = _lerp(startY, topY, Curves.fastOutSlowIn.transform(riseP));
          } else {
            final double awayP =
                ((p - riseRatio) / (1.0 - riseRatio)).clamp(0.0, 1.0).toDouble();
            y = _lerp(topY, offscreenY, Curves.easeInOut.transform(awayP));
            x = laneLeft + (screenSize.width * widget.spec.floatDriftX * awayP);
          }
        }

        double bounceOffset = 0.0;
        if (widget.spec.mode == BalloonMode.topBounce) {
          final double b = _controllerTopBounce.value.clamp(0.0, 1.0).toDouble();
          final double amplitude = balloonHeight * 0.028;
          bounceOffset = math.sin(b * math.pi) * amplitude * (1.0 - (b * 0.35));
        }

        final double driftRotation =
            math.sin((_controllerPath.value * math.pi * _driftRotationCycles) + widget.spec.phaseOffset) *
                _driftRotationAmplitude;
        final double totalRotation = driftRotation + _interactionTilt;
        final double pulseScale = _animationPulse.value;
        final double visualWidth = balloonWidth * pulseScale;
        final double targetLeft = x + _manualOffset.dx + _driftOffset.dx;
        final double targetTop = y + bounceOffset + _manualOffset.dy + _driftOffset.dy;
        final double maxTopBoundary = startY;
        final double minTopBoundary =
            widget.spec.mode == BalloonMode.floatAway ? -balloonHeight : 0.0;
        final double clampedLeft = targetLeft.clamp(
          0.0,
          math.max(0.0, screenSize.width - visualWidth),
        ).toDouble();
        final double clampedTop = targetTop.clamp(
          minTopBoundary,
          math.max(0.0, maxTopBoundary),
        ).toDouble();

        return Positioned(
          left: clampedLeft,
          top: clampedTop,
          child: GestureDetector(
            onTap: () {
              _toggleInflateDeflate();
            },
            onPanStart: (_) {
              _isDragging = true;
              _pauseForDrag();
            },
            onPanUpdate: (details) {
              setState(() {
                _manualOffset += details.delta;
                final double driftX =
                    (details.delta.dx * 6).clamp(-42.0, 42.0).toDouble();
                final double driftY =
                    (details.delta.dy * 4).clamp(-30.0, 30.0).toDouble();
                _driftOffset = Offset.lerp(
                  _driftOffset,
                  Offset(driftX, driftY),
                  0.35,
                )!;
                final double targetTilt =
                    (details.delta.dx * 0.01).clamp(-0.2, 0.2).toDouble();
                _interactionTilt = (_interactionTilt * 0.75) + (targetTilt * 0.25);
              });
            },
            onPanEnd: (_) {
              _endDragAndResume();
            },
            onPanCancel: () {
              _endDragAndResume();
            },
            child: Transform.rotate(
              angle: totalRotation,
              child: Transform.scale(
                scale: pulseScale,
                child: _buildBalloonVisual(balloonWidth, balloonHeight),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalloonVisual(double width, double height) {
    final spec = widget.spec;

    Image balloonImage({bool forShadow = false}) => Image.asset(
          'assets/images/BeginningGoogleFlutter-Balloon.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: forShadow
              ? null
              : (context, error, stackTrace) => Container(
                    width: width,
                    height: height,
                    color: Colors.blue,
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  ),
        );

    final Widget shadowLayer = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: spec.shadowBlurRadius,
        sigmaY: spec.shadowBlurRadius,
        tileMode: TileMode.decal,
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(spec.shadowColor, BlendMode.srcIn),
        child: balloonImage(forShadow: true),
      ),
    );

    Widget visibleBalloon = balloonImage();

    if (spec.gradientColors != null && spec.gradientColors!.length >= 2) {
      visibleBalloon = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: spec.gradientColors!,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: visibleBalloon,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: spec.shadowOffset,
            child: shadowLayer,
          ),
          visibleBalloon,
        ],
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}
