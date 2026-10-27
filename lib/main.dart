import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/screens/home_screen.dart';
import 'collection/fish_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FishCollection.instance =
      FishCollection(await SharedPreferences.getInstance());
  // Khóa màn hình ngang
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Ẩn status bar & navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()));
}
