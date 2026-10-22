import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/store.dart';
import '../services/ads.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final n = TextEditingController(), w = TextEditingController(), p = TextEditingController(), d = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to HustleKit')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Let\'s set up your hustle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreen)),
        const SizedBox(height: 14),
        tf('Business Name', n), tf('What you sell', w), tf('Phone', p, k: TextInputType.phone), tf('Daily Target (USD)', d, k: TextInputType.number),
        FilledButton(onPressed: () {
          if (n.text.trim().isEmpty) return;
          S.settings.putAll({'businessName': n.text.trim(), 'hustleWhat': w.text.trim(), 'phone': p.text.trim(), 'dailyTarget': double.tryParse(d.text) ?? 0.0, 'onboarded': true});
        }, child: const Text('Start')),
      ]),
    );
  }
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final code = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Unlock PRO - \$20')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('PRO: unlimited receipts and Zvikwereti, no ads. \$20 lifetime.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          SelectableText('Device ID: ${S.deviceId}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreen)),
          const SizedBox(height: 12),
          const Text('Pay \$20 USD to: EcoCash: [Your Number], InnBucks: [Your Number], BancABC Nostro: [Your Account] - Send proof to WhatsApp'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => wa(kOwnerWhatsApp, 'Hi, I paid \$20 for HustleKit PRO. My Device ID is ${S.deviceId}'), icon: const Icon(Icons.chat), label: const Text('Contact on WhatsApp')),
          const SizedBox(height: 16),
          tf('Enter Unlock Code', code),
          FilledButton(onPressed: () {
            if (verifyCode(S.deviceId, code.text)) {
              S.settings.put('isPro', true);
              Navigator.pop(context);
              snack(context, 'PRO Unlocked - Thank you!');
            } else { snack(context, 'Invalid code'); }
          }, child: const Text('Verify')),
        ]),
      );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final name = TextEditingController(text: S.g('businessName')), type = TextEditingController(text: S.g('businessType')), phone = TextEditingController(text: S.g('phone')), tin = TextEditingController(text: S.g('tin')), vat = TextEditingController(text: S.g('vat'));
  int taps = 0;

  void owner() {
    final id = TextEditingController();
    String out = '';
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (c, set) => AlertDialog(
          title: const Text('Owner Tool'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [tf('Customer Device ID', id), SelectableText(out, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
          actions: [FilledButton(onPressed: () => set(() => out = generateCode(id.text.trim().toUpperCase())), child: const Text('Generate'))])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        bottomNavigationBar: const AdBanner(),
        body: ValueListenableBuilder(valueListenable: S.settings.listenable(), builder: (_, __, ___) => ListView(padding: const EdgeInsets.all(16), children: [
          tf('Business Name', name), tf('Business Type', type), tf('Phone', phone, k: TextInputType.phone),
          tf('TIN (optional)', tin), tf('VAT number (optional)', vat),
          DropdownButtonFormField<String>(
              value: S.g('taxClearance').isEmpty ? null : S.g('taxClearance'),
              decoration: const InputDecoration(labelText: 'Do you have tax clearance?', border: OutlineInputBorder()),
              items: ['Yes', 'No'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => S.settings.put('taxClearance', v)),
          const SizedBox(height: 10),
          FilledButton(onPressed: () { S.settings.putAll({'businessName': name.text.trim(), 'businessType': type.text.trim(), 'phone': phone.text.trim(), 'tin': tin.text.trim(), 'vat': vat.text.trim()}); snack(context, 'Saved'); }, child: const Text('Save')),
          const Divider(height: 30),
          ListTile(title: const Text('Device ID'), subtitle: SelectableText(S.deviceId)),
          ListTile(title: const Text('Status'), subtitle: Text(S.isPro ? 'PRO (unlocked)' : 'Free')),
          if (!S.isPro) FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())), child: const Text('Unlock PRO - \$20')),
          ListTile(leading: const Icon(Icons.gavel), title: const Text('Disclaimer / Legal'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisclaimerScreen()))),
          ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Clear All Data'), onTap: () => showDialog(context: context, builder: (c) => AlertDialog(
                title: const Text('Clear ALL data?'), content: const Text('Receipts, debts, price list and settings (including PRO) will be deleted. Back up first.'),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: () async {
                  await S.receipts.clear(); await S.debts.clear(); await S.products.clear(); await S.expenses.clear();
                  final id = S.deviceId, pro = S.isPro;
                  await S.settings.clear(); await S.settings.put('deviceId', id); if (pro) await S.settings.put('isPro', true);
                  if (c.mounted) Navigator.pop(c);
                }, child: const Text('Delete'))]))),
          GestureDetector(onTap: () { if (++taps >= 5) { taps = 0; owner(); } }, child: const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey))))),
        ])),
      );
}

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Disclaimer / Legal')),
        body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: Text(
            'HustleKit Disclaimer:\n'
            '1. Not Fiscal: Receipts generated are NOT ZIMRA fiscal receipts. For internal records only.\n'
            '2. Not Financial Advice: HustleKit is a record keeping toolkit, not a bank, accounting, or legal service.\n'
            '3. Local Storage: All data is stored on your phone. We are not responsible for lost data if you delete the app or lose your phone. Please backup.\n'
            '4. Debt Collection: You are solely responsible for how you collect debts. Use respectful language.\n'
            '5. Pricing: USD/ZIG prices are set by you. We are not responsible for exchange rate differences.\n'
            'By using HustleKit you agree to this.\n\n'
            'Privacy Note: HustleKit does not collect, store, or transmit any bank details, EcoCash PINs, or personal financial data. PRO unlock uses only a local Device ID verification.',
            style: TextStyle(fontSize: 16, height: 1.4))),
      );
}
