import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/store.dart';
import 'services/ads.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.init();
  Ads.init();
  runApp(const HustleKitApp());
}

class HustleKitApp extends StatelessWidget {
  const HustleKitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HustleKit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen, secondary: kGold),
          appBarTheme: const AppBarTheme(backgroundColor: kGreen, foregroundColor: Colors.white),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: kGreen)),
          navigationBarTheme: const NavigationBarThemeData(indicatorColor: kGold),
        ),
        home: ValueListenableBuilder(
          valueListenable: S.settings.listenable(keys: ['onboarded']),
          builder: (_, __, ___) => S.settings.get('onboarded') == true ? const Shell() : const OnboardingScreen(),
        ),
      );
}
