import 'package:flutter/material.dart';

class Ads {
  static Future<void> init() async {}
  static void showThen(VoidCallback next) => next();
}

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
