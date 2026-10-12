import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/store.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: S.receipts.listenable(),
        builder: (_, box, __) {
          final t = {for (final p in ['Cash', 'EcoCash', 'InnBucks', 'Zvikwereti']) p: 0.0};
          for (final r in box.values.where((r) => isToday(r['date']))) { t[r['pay']] = (t[r['pay']] ?? 0) + (r['total'] as num); }
          return ListView(padding: const EdgeInsets.all(14), children: [
            Text("Today's Sales: ${money(S.todayTotal())}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kGreen)),
            const SizedBox(height: 10),
            for (final e in t.entries) Card(child: ListTile(title: Text(e.key), trailing: Text(money(e.value), style: const TextStyle(fontWeight: FontWeight.bold)))),
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: () => showDialog(context: context, builder: (c) => AlertDialog(
                      title: const Text("Clear today's sales?"), content: const Text("This deletes today's receipts."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                        FilledButton(onPressed: () {
                          for (final k in box.keys.toList()) { if (isToday(box.get(k)['date'])) box.delete(k); }
                          Navigator.pop(c);
                        }, child: const Text('Clear')),
                      ])),
                child: const Text('Clear Today')),
          ]);
        },
      );
}
