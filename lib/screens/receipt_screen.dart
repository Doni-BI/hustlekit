import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../services/store.dart';
import '../services/ads.dart';
import 'settings_screen.dart';

Future<Uint8List> buildPdf(Map r) async {
  final d = pw.Document();
  d.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(r['biz'], style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0A4D3C'))),
            pw.Text('RECEIPT / QUOTATION'),
            pw.Divider(),
            pw.Text('Client: ${r['client']}'),
            pw.Text('Date: ${r['date'].toString().substring(0, 10)}'),
            pw.Text('Payment: ${r['pay']}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(headers: ['Item', 'Qty', 'Price', 'Total'], data: [
              [r['item'], '${r['qty']}', money(r['price']), money(r['total'])]
            ]),
            pw.SizedBox(height: 10),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('TOTAL: ${money(r['total'])}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
            pw.Spacer(),
            pw.Center(child: pw.Text('Thank you for your support!')),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Text('This is not a ZIMRA fiscal receipt. For internal record keeping only.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey))),
          ])));
  return d.save();
}

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final client = TextEditingController(), item = TextEditingController(), qty = TextEditingController(text: '1'), price = TextEditingController();
  String pay = 'Cash';
  Map? last;

  Map? save() {
    if (S.receiptsFull) { Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())); return null; }
    final q = double.tryParse(qty.text) ?? 0, p = double.tryParse(price.text) ?? 0;
    if (client.text.trim().isEmpty || item.text.trim().isEmpty || q <= 0 || p <= 0) { snack(context, 'Fill client, item, qty and price'); return null; }
    if (pay == 'Zvikwereti' && S.debtsFull) { Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())); return null; }
    final r = {'biz': S.g('businessName').isEmpty ? 'My Business' : S.g('businessName'), 'client': client.text.trim(), 'item': item.text.trim(), 'qty': q, 'price': p, 'total': q * p, 'pay': pay, 'date': DateTime.now().toIso8601String()};
    S.receipts.add(r);
    if (pay == 'Zvikwereti') S.debts.add({'name': r['client'], 'amount': r['total'], 'item': r['item'], 'phone': '', 'date': r['date']});
    last = r;
    snack(context, 'Receipt saved');
    return r;
  }

  Future<void> share() async {
    final r = last ?? save();
    if (r == null) return;
    Ads.showThen(() async {
      final f = await tmpFile('receipt_${DateTime.now().millisecondsSinceEpoch}.pdf', await buildPdf(r));
      await Share.shareXFiles([XFile(f.path)], text: 'Receipt from ${r['biz']}');
    });
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
        Text(S.g('businessName'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kGreen)),
        const SizedBox(height: 10),
        tf('Client Name', client),
        tf('Item / Service', item),
        Row(children: [Expanded(child: tf('Qty', qty, k: TextInputType.number)), const SizedBox(width: 10), Expanded(child: tf('Price USD', price, k: TextInputType.number))]),
        DropdownButtonFormField<String>(
            value: pay, decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder()),
            items: ['Cash', 'EcoCash', 'InnBucks', 'Zvikwereti'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => pay = v!)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () { if (save() != null) { client.clear(); item.clear(); price.clear(); qty.text = '1'; last = null; } }, icon: const Icon(Icons.save), label: const Text('Save Receipt')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: share, icon: const Icon(Icons.share), label: const Text('Share to WhatsApp')),
      ]);
}
