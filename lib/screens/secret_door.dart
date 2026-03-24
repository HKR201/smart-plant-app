import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretDoor extends StatefulWidget {
  const SecretDoor({super.key});

  @override
  State<SecretDoor> createState() => _SecretDoorState();
}

class _SecretDoorState extends State<SecretDoor> {
  final _keyCtrl = TextEditingController();
  final _proxyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _logicCtrl = TextEditingController();
  final _personaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keyCtrl.text = prefs.getString('api_key') ?? '';
      _proxyCtrl.text = prefs.getString('proxy_url') ?? '';
      _roleCtrl.text = prefs.getString('role_box') ?? 'Expert Plant Assistant';
      _logicCtrl.text = prefs.getString('logic_box') ?? 'Use Home Inventory items';
      _personaCtrl.text = prefs.getString('persona_box') ?? 'Polite Burmese tone';
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _keyCtrl.text);
    await prefs.setString('proxy_url', _proxyCtrl.text);
    await prefs.setString('role_box', _roleCtrl.text);
    await prefs.setString('logic_box', _logicCtrl.text);
    await prefs.setString('persona_box', _personaCtrl.text);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("သိမ်းဆည်းပြီးပါပြီ")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secret Door Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _input("Gemini API Key", _keyCtrl),
            _input("Cloudflare Proxy URL", _proxyCtrl),
            const Divider(height: 40),
            _input("Role Box", _roleCtrl),
            _input("Logic Box", _logicCtrl),
            _input("Persona Box", _personaCtrl),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text("Save All Settings"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
