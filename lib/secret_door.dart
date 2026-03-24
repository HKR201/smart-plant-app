import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretDoorScreen extends StatefulWidget {
  @override
  State<SecretDoorScreen> createState() => _SecretDoorScreenState();
}

class _SecretDoorScreenState extends State<SecretDoorScreen> {
  final _keyCtrl = TextEditingController();
  final _proxyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _logicCtrl = TextEditingController();
  final _personaCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _keyCtrl.text = p.getString('gemini_api_key') ?? '';
      _proxyCtrl.text = p.getString('proxy_url') ?? '';
      _roleCtrl.text = p.getString('prompt_role') ?? 'စိုက်ပျိုးရေးပညာရှင်';
      _logicCtrl.text = p.getString('prompt_logic') ?? 'လိုအပ်သောပစ္စည်းများကိုသာ ရွေးသုံးပါ။';
      _personaCtrl.text = p.getString('prompt_persona') ?? 'ယဉ်ကျေးစွာ ပြောပြပါ။';
    });
  }

  _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('gemini_api_key', _keyCtrl.text.trim());
    await p.setString('proxy_url', _proxyCtrl.text.trim());
    await p.setString('prompt_role', _roleCtrl.text.trim());
    await p.setString('prompt_logic', _logicCtrl.text.trim());
    await p.setString('prompt_persona', _personaCtrl.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_keyCtrl, 'API Key'),
          _field(_proxyCtrl, 'Proxy URL'),
          _field(_roleCtrl, 'Role Box'),
          _field(_logicCtrl, 'Logic Box', lines: 3),
          _field(_personaCtrl, 'Persona Box'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save Settings'))
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String l, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())),
    );
  }
}
