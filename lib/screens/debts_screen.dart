import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/store.dart';
import 'settings_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  void add(BuildContext c) {
    if (S.debtsFull) { Navigator.push(c, MaterialPageRoute(builder: (_) => const PaywallScreen())); return; }
    final n = TextEditingController(), a = TextEditingController(), p = TextEditingController(), i = TextEditingController();
    showDialog(context: c, builder: (_) => AlertDialog(
      title: const Text('New Chikwereti / Isikholodo'),
      content: SingleChildScrollView(child: Column(children: [tf('Name', n), tf('Amount USD', a, k: TextInputType.number), tf('Phone', p, k: TextInputType.phone), tf('Item', i)])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final amt = double.tryParse(a.text) ?? 0;
          if (n.text.trim().isEmpty || amt <= 0) return;
          S.debts.add({'name': n.text.trim(), 'amount': amt, 'phone': p.text.trim(), 'item': i.text.trim(), 'date': DateTime.now().toIso8601String()});
          Navigator.pop(c);
        }, child: const Text('Save')),
      ]));
  }

  void remind(BuildContext c, Map d) => showDialog(context: c, builder: (_) => AlertDialog(
        title: const Text('Send Respectfully?'),
        content: const Text('Be respectful. HustleKit is not responsible for how you collect debts. Send polite reminder?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            Navigator.pop(c);
            wa(d['phone'] ?? '', 'Mhoro ${d['name']}, chikwereti / isikholodo senu se \$${(d['amount'] as num).toStringAsFixed(2)} for ${d['item']}... Thanks - ${S.g('businessName')}');
          }, child: const Text('Send')),
        ]));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: S.debts.listenable(),
        builder: (_, box, __) => Scaffold(
          floatingActionButton: FloatingActionButton(backgroundColor: kGold, onPressed: () => add(context), child: const Icon(Icons.add)),
          body: Column(children: [
            Container(width: double.infinity, color: kGreen, padding: const EdgeInsets.all(14),
                child: Text('Total owed: ${money(S.owed())}', style: const TextStyle(color: kGold, fontSize: 20, fontWeight: FontWeight.w900))),
            Expanded(child: ListView(children: [
              for (final k in box.keys)
                Builder(builder: (_) {
                  final d = Map.from(box.get(k));
                  return Card(child: ListTile(
                    title: Text('${d['name']}  ${money(d['amount'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${d['item']} · ${d['date'].toString().substring(0, 10)}\n${d['phone']}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'call' && (d['phone'] ?? '') != '') launchUrl(Uri.parse('tel:${d['phone']}'));
                        if (v == 'paid') box.delete(k);
                        if (v == 'remind') remind(context, d);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'call', child: Text('Call client')),
                        PopupMenuItem(value: 'paid', child: Text('Mark as Paid')),
                        PopupMenuItem(value: 'remind', child: Text('Send Reminder')),
                      ]),
                  ));
                }),
            ])),
          ]),
        ),
      );
}
