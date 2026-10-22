import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/store.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  void addPurchase(BuildContext c) {
    final sup = TextEditingController(), amt = TextEditingController();
    showDialog(context: c, builder: (_) => AlertDialog(
          title: const Text('Wholesaler purchase'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [tf('Wholesaler / supplier', sup), tf('Amount USD', amt, k: TextInputType.number)]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final a = double.tryParse(amt.text) ?? 0;
              if (a <= 0) return;
              S.expenses.add({'supplier': sup.text.trim().isEmpty ? 'Wholesaler' : sup.text.trim(), 'amount': a, 'date': DateTime.now().toIso8601String()});
              Navigator.pop(c);
            }, child: const Text('Save')),
          ]));
  }

  Widget stat(String l, double v) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        Text(l, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        Text(money(v), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kGreen)),
      ]))));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([S.receipts.listenable(), S.expenses.listenable(), S.settings.listenable()]),
        builder: (_, __) {
          final now = DateTime.now(), day = DateTime(now.year, now.month, now.day);
          final week = day.subtract(Duration(days: now.weekday - 1)), month = DateTime(now.year, now.month);
          final r12 = S.salesSince(now.subtract(const Duration(days: 365)));
          final level = r12 >= kVatLimit ? 2 : (r12 >= kVatWarn ? 1 : 0);
          final t = {for (final p in ['Cash', 'EcoCash', 'InnBucks', 'Zvikwereti']) p: 0.0};
          for (final r in S.receipts.values.where((r) => isToday(r['date']) && r['type'] != 'Quotation')) { t[r['pay']] = (t[r['pay']] ?? 0) + (r['total'] as num); }
          final buys = S.expenses.keys.where((k) => isToday(S.expenses.get(k)['date'])).toList();
          final bought = buys.fold(0.0, (a, k) => a + (S.expenses.get(k)['amount'] as num));
          final clearance = S.g('taxClearance');
          return ListView(padding: const EdgeInsets.all(14), children: [
            Row(children: [stat('Today', S.salesSince(day)), stat('This week', S.salesSince(week)), stat('This month', S.salesSince(month))]),
            const SizedBox(height: 6),
            for (final e in t.entries) Card(child: ListTile(dense: true, title: Text(e.key), trailing: Text(money(e.value), style: const TextStyle(fontWeight: FontWeight.bold)))),
            Card(
              color: level == 2 ? Colors.red.shade100 : (level == 1 ? Colors.orange.shade100 : null),
              child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('VAT watch (last 12 months)', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${money(r12)} / ${money(kVatLimit)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kGreen)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: (r12 / kVatLimit).clamp(0, 1).toDouble(), minHeight: 10, color: level == 2 ? Colors.red : (level == 1 ? Colors.orange : kGold)),
                if (level == 1) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Close to VAT threshold', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                if (level == 2) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Register for VAT now!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
              ])),
            ),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Expenses: wholesaler purchases today', style: TextStyle(fontWeight: FontWeight.bold)),
              if (clearance.isEmpty) ...[
                const Text('Do you have tax clearance?'),
                Row(children: [
                  TextButton(onPressed: () => S.settings.put('taxClearance', 'Yes'), child: const Text('Yes')),
                  TextButton(onPressed: () => S.settings.put('taxClearance', 'No'), child: const Text('No')),
                ]),
              ] else
                Row(children: [Text('Tax clearance: $clearance'), TextButton(onPressed: () => S.settings.put('taxClearance', ''), child: const Text('Change'))]),
              for (final k in buys) Builder(builder: (_) {
                final e = S.expenses.get(k);
                return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(e['supplier']),
                    subtitle: clearance == 'No' ? Text('+ ${money((e['amount'] as num) * kWithholding)} extra 5%') : null,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(e['amount'])), IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => S.expenses.delete(k))]));
              }),
              Text('Bought today: ${money(bought)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (clearance == 'No') Container(
                margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10), color: Colors.orange.shade100,
                child: Text('Extra 5% paid to wholesalers (no tax clearance): ${money(bought * kWithholding)}\nGet a ZIMRA tax clearance so suppliers stop withholding this.', style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: () => addPurchase(context), icon: const Icon(Icons.add), label: const Text('Add purchase')),
              const SizedBox(height: 6),
              const Text('Estimates only, not tax advice. Confirm rates and thresholds with ZIMRA.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]))),
            OutlinedButton(
                onPressed: () => showDialog(context: context, builder: (c) => AlertDialog(
                      title: const Text("Clear today's sales?"), content: const Text("This permanently deletes today's saved receipts (quotations are kept) and lowers your 12-month VAT total."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                        FilledButton(onPressed: () {
                          for (final k in S.receipts.keys.toList()) { final r = S.receipts.get(k); if (isToday(r['date']) && r['type'] != 'Quotation') S.receipts.delete(k); }
                          Navigator.pop(c);
                        }, child: const Text('Clear')),
                      ])),
                child: const Text('Clear Today')),
          ]);
        },
      );
}
