import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../services/store.dart';
import '../services/ads.dart';

class HustleCardScreen extends StatefulWidget {
  const HustleCardScreen({super.key});
  @override
  State<HustleCardScreen> createState() => _HustleCardScreenState();
}

class _HustleCardScreenState extends State<HustleCardScreen> {
  static const keys = ['businessName', 'hustleWhat', 'hustleTarget', 'hustleWhere', 'dailyTarget', 'monthlyTarget', 'hustleWhy', 'hustleStory'];
  static const labels = ['Business Name', 'What I sell', 'Who is my target customer', 'Where I hustle', 'Daily target (USD)', 'Monthly target (USD)', 'Why buy from me', 'My hustle story'];
  late final Map<String, TextEditingController> c = {for (final k in keys) k: TextEditingController(text: S.g(k))};
  final sc = ScreenshotController();

  void save() {
    for (final k in keys) {
      S.settings.put(k, k.endsWith('Target') && k.startsWith(RegExp('daily|monthly')) ? (double.tryParse(c[k]!.text) ?? 0) : c[k]!.text.trim());
    }
    snack(context, 'Hustle Card saved');
  }

  Future<void> shareIt() async {
    save();
    final b = await sc.capture(pixelRatio: 2);
    if (b == null) return;
    final f = await tmpFile('hustle_card.png', b);
    await Share.shareXFiles([XFile(f.path)], text: 'My Hustle - ${c['businessName']!.text}');
  }

  void progress() {
    final t = S.todayTotal(), d = double.tryParse(c['dailyTarget']!.text) ?? 0;
    showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Today\'s Progress'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${money(t)} / ${money(d)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: d > 0 ? (t / d).clamp(0, 1).toDouble() : 0, minHeight: 12, color: kGold),
          ])));
  }

  Widget row(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text.rich(TextSpan(children: [
        TextSpan(text: '$l: ', style: const TextStyle(color: kGold, fontWeight: FontWeight.bold)),
        TextSpan(text: v, style: const TextStyle(color: Colors.white)),
      ])));

  @override
  Widget build(BuildContext context) {
    final t = S.todayTotal(), d = double.tryParse(c['dailyTarget']!.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('My Hustle Card')),
      bottomNavigationBar: const AdBanner(),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        for (var i = 0; i < keys.length; i++)
          Focus(onFocusChange: (_) => setState(() {}), child: tf(labels[i], c[keys[i]]!, k: i == 4 || i == 5 ? TextInputType.number : null, lines: i >= 6 ? 3 : 1)),
        ListenableBuilder(listenable: Listenable.merge(c.values.toList()), builder: (_, __) => Screenshot(controller: sc, child: Container(
          padding: const EdgeInsets.all(20), color: kGreen,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['businessName']!.text.toUpperCase(), style: const TextStyle(color: kGold, fontSize: 28, fontWeight: FontWeight.w900)),
            const Text('100% Zimbabwean Hustle', style: TextStyle(color: Colors.white70)),
            const Divider(color: kGold),
            row('What I sell', c['hustleWhat']!.text),
            row('Target', c['hustleTarget']!.text),
            row('Where', c['hustleWhere']!.text),
            row('Why buy from me', c['hustleWhy']!.text),
            row('Story', c['hustleStory']!.text),
            const Divider(color: kGold),
            Text('Daily Target ${c['dailyTarget']!.text.isEmpty ? '\$0' : '\$${c['dailyTarget']!.text}'}   Monthly \$${c['monthlyTarget']!.text.isEmpty ? '0' : c['monthlyTarget']!.text}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Phone: ${S.g('phone')}', style: const TextStyle(color: Colors.white)),
            const Align(alignment: Alignment.centerRight, child: Text('Powered by HustleKit', style: TextStyle(color: kGold, fontSize: 11))),
          ]),
        ))),
        const SizedBox(height: 10),
        Text('Today: ${money(t)} / ${money(d)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        LinearProgressIndicator(value: d > 0 ? (t / d).clamp(0, 1).toDouble() : 0, minHeight: 10, color: kGold),
        const SizedBox(height: 10),
        FilledButton(onPressed: save, child: const Text('Save My Hustle Card')),
        const SizedBox(height: 6),
        FilledButton(onPressed: shareIt, child: const Text('Share My Hustle')),
        const SizedBox(height: 6),
        OutlinedButton(onPressed: progress, child: const Text('View Progress')),
      ]),
    );
  }
}
