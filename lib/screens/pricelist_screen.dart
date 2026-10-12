import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../services/store.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});
  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final n = TextEditingController(), usd = TextEditingController(), zig = TextEditingController();
  final sc = ScreenshotController();
  Color bg = kGreen;

  Future<void> shareIt() async {
    final b = await sc.capture(pixelRatio: 2);
    if (b == null) return;
    final f = await tmpFile('pricelist.png', b);
    await Share.shareXFiles([XFile(f.path)], text: 'Price list - ${S.g('businessName')}');
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: S.products.listenable(),
        builder: (_, box, __) => ListView(padding: const EdgeInsets.all(14), children: [
          tf('Product / Service', n),
          Row(children: [Expanded(child: tf('Price USD', usd, k: TextInputType.number)), const SizedBox(width: 10), Expanded(child: tf('Price ZIG', zig, k: TextInputType.number))]),
          FilledButton(onPressed: () {
            if (n.text.trim().isEmpty) return;
            S.products.add({'name': n.text.trim(), 'usd': double.tryParse(usd.text) ?? 0, 'zig': double.tryParse(zig.text) ?? 0});
            n.clear(); usd.clear(); zig.clear();
          }, child: const Text('Add Item')),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final c in [kGreen, Colors.black87, const Color(0xFF7B1FA2), const Color(0xFFC62828)])
              GestureDetector(onTap: () => setState(() => bg = c), child: Container(margin: const EdgeInsets.all(6), width: 32, height: 32, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: bg == c ? kGold : Colors.white, width: 3)))),
          ]),
          Screenshot(controller: sc, child: Container(
            padding: const EdgeInsets.all(20), color: bg,
            child: Column(children: [
              Text(S.g('businessName').toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: kGold, fontSize: 28, fontWeight: FontWeight.w900)),
              const Text('PRICE LIST', style: TextStyle(color: Colors.white, letterSpacing: 4)),
              const Divider(color: kGold),
              for (final k in box.keys)
                Builder(builder: (_) {
                  final p = box.get(k);
                  return Row(children: [
                    Expanded(child: Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 18))),
                    Text('${money(p['usd'])}  |  ZiG ${(p['zig'] as num).toStringAsFixed(2)}', style: const TextStyle(color: kGold, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 16), onPressed: () => box.delete(k)),
                  ]);
                }),
              const Divider(color: kGold),
              Text('Call/WhatsApp: ${S.g('phone')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: shareIt, icon: const Icon(Icons.share), label: const Text('Share to WhatsApp Status')),
        ]),
      );
}
