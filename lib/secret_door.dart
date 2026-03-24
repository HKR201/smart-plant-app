import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretDoorScreen extends StatefulWidget {
  const SecretDoorScreen({super.key});
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
      _roleCtrl.text = p.getString('prompt_role') ?? 'Expert Gardener';
      _logicCtrl.text = p.getString('prompt_logic') ?? 'Analyze image and give advice.';
      _personaCtrl.text = p.getString('prompt_persona') ?? 'Friendly and polite.';
    });
  }

  _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('gemini_api_key', _keyCtrl.text);
    await p.setString('proxy_url', _proxyCtrl.text);
    await p.setString('prompt_role', _roleCtrl.text);
    await p.setString('prompt_logic', _logicCtrl.text);
    await p.setString('prompt_persona', _personaCtrl.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _keyCtrl, decoration: const InputDecoration(labelText: 'API Key')),
          TextField(controller: _proxyCtrl, decoration: const InputDecoration(labelText: 'Proxy URL')),
          TextField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'Role Box')),
          TextField(controller: _logicCtrl, decoration: const InputDecoration(labelText: 'Logic Box'), maxLines: 3),
          TextField(controller: _personaCtrl, decoration: const InputDecoration(labelText: 'Persona Box')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save Settings'))
        ],
      ),
    );
  }
}
