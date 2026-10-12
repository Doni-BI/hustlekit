import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String _secret = "HUSTLE2026_ZW_SECRET";
const kGreen = Color(0xFF0A4D3C);
const kGold = Color(0xFFFFC300);
const kOwnerWhatsApp = '263700000000'; // TODO: your number, digits only

String generateCode(String deviceId) {
  final h = sha256.convert(utf8.encode(_secret + deviceId)).toString().substring(0, 8).toUpperCase();
  return 'HUSTLE-${h.substring(0, 4)}-${h.substring(4)}';
}

bool verifyCode(String deviceId, String code) => generateCode(deviceId) == code.toUpperCase().trim();

class S {
  static late Box receipts, debts, products, settings;
  static Future<void> init() async {
    await Hive.initFlutter();
    receipts = await Hive.openBox('receipts_box');
    debts = await Hive.openBox('debts_box');
    products = await Hive.openBox('products_box');
    settings = await Hive.openBox('settings_box');
    if (settings.get('deviceId') == null) {
      const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final r = Random.secure();
      await settings.put('deviceId', 'HK-${List.generate(6, (_) => c[r.nextInt(c.length)]).join()}');
    }
  }
  static bool get isPro => settings.get('isPro', defaultValue: false) == true;
  static String get deviceId => settings.get('deviceId');
  static String g(String k) => (settings.get(k) ?? '').toString();
  static double n(String k) => (settings.get(k) as num?)?.toDouble() ?? 0;
  static bool get receiptsFull => !isPro && receipts.length >= 10;
  static bool get debtsFull => !isPro && debts.length >= 10;
  static double todayTotal() => receipts.values.where((r) => isToday(r['date'])).fold(0.0, (a, r) => a + (r['total'] as num));
  static double owed() => debts.values.fold(0.0, (a, d) => a + (d['amount'] as num));
}

bool isToday(String iso) {
  final d = DateTime.parse(iso).toLocal(), n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

String money(num v) => '\$${v.toStringAsFixed(2)}';
void snack(BuildContext c, String s) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

Future<void> wa(String phone, String msg) async {
  var p = phone.replaceAll(RegExp(r'\D'), '');
  if (p.startsWith('0')) p = '263${p.substring(1)}';
  await launchUrl(Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
}

Future<File> tmpFile(String name, List<int> bytes) async {
  final d = await getTemporaryDirectory();
  return File('${d.path}/$name')..writeAsBytesSync(bytes);
}

Widget tf(String l, TextEditingController c, {TextInputType? k, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: k, maxLines: lines, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
