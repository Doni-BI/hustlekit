import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'store.dart';

class Ads {
  static InterstitialAd? _i;
  static Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      load();
    } catch (_) {}
  }
  static void load() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (a) => _i = a, onAdFailedToLoad: (_) => _i = null));
  }
  static void showThen(VoidCallback next) {
    final a = _i;
    if (S.isPro || a == null) return next();
    _i = null;
    a.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (x) { x.dispose(); load(); next(); },
        onAdFailedToShowFullScreenContent: (x, e) { x.dispose(); next(); });
    a.show();
  }
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _b;
  bool _ok = false;
  @override
  void initState() {
    super.initState();
    if (S.isPro) return;
    try {
      _b = BannerAd(
          adUnitId: 'ca-app-pub-3940256099942544/6300978111',
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
              onAdLoaded: (_) { if (mounted) setState(() => _ok = true); },
              onAdFailedToLoad: (ad, e) { ad.dispose(); _b = null; }))..load();
    } catch (_) {}
  }
  @override
  void dispose() { _b?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
      valueListenable: S.settings.listenable(keys: ['isPro']),
      builder: (_, __, ___) => (S.isPro || !_ok || _b == null)
          ? const SizedBox.shrink()
          : SizedBox(height: 50, width: 320, child: AdWidget(ad: _b!)));
}
