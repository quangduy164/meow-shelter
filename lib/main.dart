import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio/game_audio.dart';

import 'ui/design.dart';
import 'ui/screens/home_screen.dart';
import 'collection/fish_collection.dart';
import 'camp/camp_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  FishCollection.instance = FishCollection(preferences);
  CampState.instance = CampState(preferences);
  GameAudio.instance.initialize(preferences);
  // Khóa màn hình ngang
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Ẩn status bar & navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: DS.theme,
    navigatorObservers: [homeRouteObserver],
    // Every route, dialog and game canvas is laid out in design units and
    // scaled to the real screen; see lib/ui/responsive.dart.
    builder: (context, child) => UiScaleBox(child: child!),
    home: const HomeScreen(),
  ));
}
