import 'package:flutter/material.dart';
import '../data/business_ideas_data.dart';
import '../services/store.dart';
import '../services/ads.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});
  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  String q = '', cat = 'All';

  void detail(Map<String, dynamic> i) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kGreen)),
          Text(i['category']),
          const SizedBox(height: 10),
          Text('Needs: ${i['needs']}'),
          Text('Startup: ~${money(i['startup'])}'),
          Text('Where to sell: ${i['whereToSell']}'),
          Text('Pro tip: ${i['proTip']}'),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
            S.settings.put('businessType', i['name']);
            Navigator.pop(c);
            snack(context, 'Hustle set!');
          }, child: const Text('Start This Hustle'))),
        ])));

  @override
  Widget build(BuildContext context) {
    final cats = ['All', ...{for (final i in businessIdeas) i['category'] as String}];
    final list = businessIdeas.where((i) => (cat == 'All' || i['category'] == cat) && i['name'].toString().toLowerCase().contains(q.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Business Ideas')),
      bottomNavigationBar: const AdBanner(),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search hustles', border: OutlineInputBorder()))),
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in cats) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(c), selected: cat == c, selectedColor: kGold, onSelected: (_) => setState(() => cat = c))),
        ])),
        Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (_, n) => ListTile(
              title: Text(list[n]['name']), subtitle: Text('${list[n]['category']} · from ${money(list[n]['startup'])}'),
              trailing: const Icon(Icons.chevron_right), onTap: () => detail(list[n])))),
      ]),
    );
  }
}
