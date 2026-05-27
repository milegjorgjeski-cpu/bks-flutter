import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080810),
  ));
  runApp(const BksApp());
}

class BksApp extends StatelessWidget {
  const BksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balkan Karaoke Studio',
      debugShowCheckedModeBanner: false,
      theme: BksTheme.dark,
      home: const HomeScreen(),
    );
  }
}
