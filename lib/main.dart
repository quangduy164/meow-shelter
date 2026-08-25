import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'level_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Khóa màn hình ngang
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Ẩn status bar & navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: LevelSelectScreen()));
}
