import 'package:flutter/material.dart';
import 'helpers/database_helper.dart';
import 'screens/home_screen.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.chargerDonnees();
  runApp(const CornelMusculationApp());
}

class CornelMusculationApp extends StatelessWidget {
  const CornelMusculationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F6F9),
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF09090B), // Noir OLED moderne
            cardColor: const Color(0xFF18181B), // Cartes subtiles
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8), // Cyan lumineux
              secondary: Color(0xFF10B981), // Vert menthe
              surface: Color(0xFF18181B),
            ),
            cardTheme: CardTheme(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
