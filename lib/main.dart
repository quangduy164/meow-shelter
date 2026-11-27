import 'dart:async';

import 'fishing/player_identity.dart';
import 'online/firebase_session.dart';
import 'package:material_ui/material_ui.dart';
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
  unawaited(PlayerIdentity.load(preferences).saved);
  FishCollection.instance = FishCollection(preferences);
  CampState.instance = CampState(preferences);
  GameAudio.instance.initialize(preferences);
  // Khóa màn hình ngang và ẩn thanh hệ thống trước khung hình đầu tiên, để
  // trang chủ không bị dàn lại khi cửa sổ đổi kích thước.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Ẩn status bar & navigation bar
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: DS.theme,
    navigatorObservers: [homeRouteObserver],
    // Every route, dialog and game canvas is laid out in design units and
    // scaled to the real screen; see lib/ui/responsive.dart.
    builder: (context, child) => UiScaleBox(child: child!),
    home: const HomeScreen(),
  ));
  // Guest sign-in runs in the background; Home never waits for the network.
  unawaited(FirebaseSession.instance.connect());
}
