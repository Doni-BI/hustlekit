import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/store.dart';
import '../services/ads.dart';
import 'receipt_screen.dart';
import 'debts_screen.dart';
import 'pricelist_screen.dart';
import 'sales_screen.dart';
import 'ideas_screen.dart';
import 'hustle_card_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('HustleKit'), actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))
        ]),
        body: IndexedStack(index: i, children: [
          HomeScreen(go: (n) => setState(() => i = n)),
          const ReceiptScreen(),
          const DebtsScreen(),
          const PriceListScreen(),
          const SalesScreen(),
        ]),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          const AdBanner(),
          NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Receipt'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Zvikwereti'),
            NavigationDestination(icon: Icon(Icons.sell), label: 'Price List'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Sales'),
          ]),
        ]),
      );
}

class HomeScreen extends StatelessWidget {
  final void Function(int) go;
  const HomeScreen({super.key, required this.go});
  void push(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final cards = <(String, IconData, VoidCallback)>[
      ('Make Receipt', Icons.receipt_long, () => go(1)),
      ('Zvikwereti / Izikholodo', Icons.account_balance_wallet, () => go(2)),
      ('Make Price List', Icons.sell, () => go(3)),
      ("Today's Sales", Icons.bar_chart, () => go(4)),
      ('Business Ideas (110+)', Icons.lightbulb, () => push(context, const IdeasScreen())),
      ('My Hustle Card', Icons.badge, () => push(context, const HustleCardScreen())),
    ];
    return AnimatedBuilder(
      animation: Listenable.merge([S.receipts.listenable(), S.debts.listenable(), S.settings.listenable()]),
      builder: (_, __) {
        final today = S.todayTotal(), target = S.n('dailyTarget');
        return ListView(padding: const EdgeInsets.all(14), children: [
          Row(children: [
            const Text('HustleKit', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kGreen)),
            const SizedBox(width: 8),
            Chip(label: const Text('100% Offline'), backgroundColor: kGold.withOpacity(.4)),
            if (S.isPro) const Padding(padding: EdgeInsets.only(left: 6), child: Chip(label: Text('PRO'), backgroundColor: kGold)),
          ]),
          Row(children: [
            Expanded(child: _stat('Money today', money(today))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Owed to you', money(S.owed()))),
          ]),
          if (target > 0) ...[
            const SizedBox(height: 10),
            Text('Today: ${money(today)} / ${money(target)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            LinearProgressIndicator(value: (today / target).clamp(0, 1).toDouble(), minHeight: 10, color: kGold, backgroundColor: Colors.grey.shade300),
          ],
          if (!S.isPro && S.receipts.length >= 8)
            Card(color: kGold, child: ListTile(
              title: const Text('Upgrade to PRO', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${S.receipts.length}/10 free receipts used'),
              onTap: () => push(context, const PaywallScreen()))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.15,
            children: [
              for (final c in cards)
                InkWell(onTap: c.$3, child: Card(color: kGreen, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(c.$2, size: 38, color: kGold),
                  Padding(padding: const EdgeInsets.all(8), child: Text(c.$1, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ]))),
            ],
          ),
        ]);
      },
    );
  }

  Widget _stat(String l, String v) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Text(l, style: const TextStyle(color: Colors.black54)),
        Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreen)),
      ])));
}
