import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/store.dart';
import '../services/ads.dart';
import 'receipt_screen.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  void convert(BuildContext c, dynamic k, Map r) => showDialog(
      context: c,
      builder: (_) => SimpleDialog(title: const Text('Paid by?'), children: [
            for (final p in ['Cash', 'EcoCash', 'InnBucks', 'Zvikwereti'])
              SimpleDialogOption(onPressed: () {
                Navigator.pop(c);
                if (p == 'Zvikwereti' && S.debtsFull) { snack(c, 'Zvikwereti limit reached. Unlock PRO.'); return; }
                final n = {...r, 'type': 'Receipt', 'pay': p, 'no': nextNo(false), 'date': DateTime.now().toIso8601String()};
                S.receipts.put(k, n);
                if (p == 'Zvikwereti') S.debts.add({'name': r['client'], 'amount': r['total'], 'item': docItems(r).map((e) => e['name']).join(', '), 'phone': '', 'date': n['date']});
                snack(c, 'Converted to receipt ${n['no']}');
              }, child: Text(p)),
          ]));

  void actions(BuildContext c, dynamic k, Map r) => showModalBottomSheet(
      context: c,
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.share), title: const Text('Share PDF'), onTap: () { Navigator.pop(c); shareDoc(r); }),
            if (r['type'] == 'Quotation') ListTile(leading: const Icon(Icons.swap_horiz), title: const Text('Convert to receipt'), onTap: () { Navigator.pop(c); convert(c, k, r); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete'), onTap: () { Navigator.pop(c); S.receipts.delete(k); }),
          ])));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saved Documents')),
        bottomNavigationBar: const AdBanner(),
        body: ValueListenableBuilder(
            valueListenable: S.receipts.listenable(),
            builder: (_, box, __) {
              final keys = box.keys.toList().reversed.toList();
              if (keys.isEmpty) return const Center(child: Text('No saved documents yet'));
              return ListView(children: [
                for (final k in keys)
                  Builder(builder: (_) {
                    final r = Map.from(box.get(k));
                    final q = r['type'] == 'Quotation';
                    return ListTile(
                        leading: Icon(q ? Icons.request_quote : Icons.receipt_long, color: kGreen),
                        title: Text('${r['no'] ?? (q ? 'Quotation' : 'Receipt')} · ${r['client']}'),
                        subtitle: Text('${r['date'].toString().substring(0, 10)} · ${q ? 'Quotation' : r['pay']}'),
                        trailing: Text(money(r['total']), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => actions(context, k, r));
                  }),
              ]);
            }),
      );
}
