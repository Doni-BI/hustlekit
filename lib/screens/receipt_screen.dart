import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../services/store.dart';
import '../services/ads.dart';
import 'settings_screen.dart';
import 'docs_screen.dart';

List<Map> docItems(Map r) => r['items'] != null
    ? (r['items'] as List).map((e) => Map.from(e)).toList()
    : [{'name': r['item'], 'qty': r['qty'], 'price': r['price']}];

String nextNo(bool quote) {
  final n = ((S.settings.get('docSeq') ?? 0) as int) + 1;
  S.settings.put('docSeq', n);
  return '${quote ? 'Q' : 'R'}-${n.toString().padLeft(4, '0')}';
}

Future<Uint8List> buildPdf(Map r) async {
  final quote = r['type'] == 'Quotation';
  final d = pw.Document();
  d.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(r['biz'], style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0A4D3C'))),
            if ((r['phone'] ?? '') != '') pw.Text('Tel: ${r['phone']}'),
            if ((r['tin'] ?? '') != '') pw.Text('TIN: ${r['tin']}'),
            if ((r['vat'] ?? '') != '') pw.Text('VAT No: ${r['vat']}'),
            pw.SizedBox(height: 6),
            pw.Text(quote ? 'QUOTATION' : 'RECEIPT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('No: ${r['no'] ?? '-'}'),
            pw.Text('Client: ${r['client']}'),
            pw.Text('Date: ${r['date'].toString().substring(0, 10)}'),
            if (!quote) pw.Text('Payment: ${r['pay']}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(headers: ['Item', 'Qty', 'Price', 'Total'], data: [
              for (final i in docItems(r)) [i['name'], '${i['qty']}', money(i['price']), money(i['qty'] * i['price'])]
            ]),
            pw.SizedBox(height: 10),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('TOTAL: ${money(r['total'])}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
            if (quote) pw.Padding(padding: const pw.EdgeInsets.only(top: 8), child: pw.Text('This quotation is valid for 7 days.')),
            pw.Spacer(),
            pw.Center(child: pw.Text('Thank you for your support!')),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Text('This is not a ZIMRA fiscal receipt. For internal record keeping only.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey))),
          ])));
  return d.save();
}

void shareDoc(Map r) => Ads.showThen(() async {
      final f = await tmpFile('${r['no'] ?? 'doc'}.pdf', await buildPdf(r));
      await Share.shareXFiles([XFile(f.path)], text: '${r['type'] ?? 'Receipt'} from ${r['biz']}');
    });

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final client = TextEditingController(), iname = TextEditingController(), qty = TextEditingController(text: '1'), price = TextEditingController();
  String type = 'Receipt', pay = 'Cash';
  final List<Map> items = [];
  Map? last;
  double get total => items.fold(0.0, (a, i) => a + i['qty'] * i['price']);

  bool addItem() {
    final q = double.tryParse(qty.text) ?? 0, p = double.tryParse(price.text) ?? 0;
    if (iname.text.trim().isEmpty || q <= 0 || p <= 0) { snack(context, 'Fill item, qty and price'); return false; }
    setState(() { items.add({'name': iname.text.trim(), 'qty': q, 'price': p}); iname.clear(); price.clear(); qty.text = '1'; });
    return true;
  }

  void pw_() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));

  Map? save() {
    if (iname.text.trim().isNotEmpty && price.text.isNotEmpty && !addItem()) return null;
    if (S.receiptsFull) { pw_(); return null; }
    if (client.text.trim().isEmpty || items.isEmpty) { snack(context, 'Add a client and at least one item'); return null; }
    final quote = type == 'Quotation';
    if (!quote && pay == 'Zvikwereti' && S.debtsFull) { pw_(); return null; }
    final r = {
      'no': nextNo(quote), 'type': type, 'biz': S.g('businessName').isEmpty ? 'My Business' : S.g('businessName'), 'phone': S.g('phone'), 'tin': S.g('tin'), 'vat': S.g('vat'),
      'client': client.text.trim(), 'items': items.map((e) => Map.from(e)).toList(), 'total': total, 'pay': quote ? '-' : pay, 'date': DateTime.now().toIso8601String(),
    };
    S.receipts.add(r);
    if (!quote && pay == 'Zvikwereti') S.debts.add({'name': r['client'], 'amount': r['total'], 'item': items.map((e) => e['name']).join(', '), 'phone': '', 'date': r['date']});
    last = r;
    snack(context, '$type ${r['no']} saved');
    return r;
  }

  void reset() => setState(() { client.clear(); items.clear(); last = null; });

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
        SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'Receipt', label: Text('Receipt')), ButtonSegment(value: 'Quotation', label: Text('Quotation'))],
            selected: {type}, onSelectionChanged: (v) => setState(() => type = v.first)),
        const SizedBox(height: 12),
        tf('Client Name', client),
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: kGreen)),
        for (var i = 0; i < items.length; i++)
          ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(items[i]['name']),
              subtitle: Text('${items[i]['qty']} x ${money(items[i]['price'])}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(items[i]['qty'] * items[i]['price'])), IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => items.removeAt(i)))])),
        const SizedBox(height: 6),
        tf('Item / Service', iname),
        Row(children: [Expanded(child: tf('Qty', qty, k: TextInputType.number)), const SizedBox(width: 10), Expanded(child: tf('Price USD', price, k: TextInputType.number))]),
        OutlinedButton.icon(onPressed: addItem, icon: const Icon(Icons.add), label: const Text('Add item')),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Total: ${money(total)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreen))),
        if (type == 'Receipt')
          DropdownButtonFormField<String>(
              value: pay, decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder()),
              items: ['Cash', 'EcoCash', 'InnBucks', 'Zvikwereti'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => pay = v!)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () { if (save() != null) reset(); }, icon: const Icon(Icons.save), label: Text('Save $type')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () { final r = last ?? save(); if (r != null) { shareDoc(r); reset(); } }, icon: const Icon(Icons.share), label: const Text('Share to WhatsApp')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocsScreen())), icon: const Icon(Icons.folder), label: const Text('Saved receipts & quotations')),
      ]);
}
