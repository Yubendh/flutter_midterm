import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/animated_balloon.dart';
import '../widgets/animated_birds.dart';
import '../widgets/animated_clouds.dart';

const Color _skyColor = Color(0xFFAEDEF4);    // sky background colour
const String _appBarTitle = 'Balloon Animation'; // title bar text
const double _windVolume = 0.5;               // 0.0 = silent, 1.0 = full
const String _windAudioFile = 'audio/wind.mp3';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AudioPlayer _windPlayer;

  @override
  void initState() {
    super.initState();
    _windPlayer = AudioPlayer();
    _startWind();
  }

  Future<void> _startWind() async {
    await _windPlayer.setReleaseMode(ReleaseMode.loop);
    await _windPlayer.setVolume(_windVolume);
    await _windPlayer.play(AssetSource(_windAudioFile));
  }

  @override
  void dispose() {
    _windPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _skyColor,
      appBar: AppBar(
        title: const Text(_appBarTitle),
      ),
      // Stack renders back-to-front: clouds → birds → balloons
      body: const SafeArea(
        child: Stack(
          children: [
            AnimatedCloudsWidget(),
            AnimatedBirdsWidget(),
            AnimatedBalloonWidget(),
          ],
        ),
      ),
    );
  }
}
