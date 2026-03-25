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
  final _weatherCtrl = TextEditingController(); 
  final _roleCtrl = TextEditingController();
  final _logicCtrl = TextEditingController();
  final _personaCtrl = TextEditingController();

  @override 
  void initState() { 
    super.initState(); 
    _load(); 
  }

  _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keyCtrl.text = prefs.getString('api_key') ?? '';
      _proxyCtrl.text = prefs.getString('proxy_url') ?? '';
      _weatherCtrl.text = prefs.getString('weather_api') ?? '';
      _roleCtrl.text = prefs.getString('role_box') ?? 'Expert Plant Assistant';
      _logicCtrl.text = prefs.getString('logic_box') ?? 'Use Home Inventory items';
      _personaCtrl.text = prefs.getString('persona_box') ?? 'Polite Burmese tone';
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _keyCtrl.text);
    await prefs.setString('proxy_url', _proxyCtrl.text);
    await prefs.setString('weather_api', _weatherCtrl.text);
    await prefs.setString('role_box', _roleCtrl.text);
    await prefs.setString('logic_box', _logicCtrl.text);
    await prefs.setString('persona_box', _personaCtrl.text);
    if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secret Door Settings")),
      body: ListView(
        padding: const EdgeInsets.all(20), 
        children: [
          _in("Gemini Key", _keyCtrl), 
          _in("Google Script Proxy URL", _proxyCtrl), 
          _in("OpenWeather API Key", _weatherCtrl), 
          const Divider(height: 40),
          _in("Role", _roleCtrl), 
          _in("Logic", _logicCtrl), 
          _in("Persona", _personaCtrl),
          const SizedBox(height: 20), 
          ElevatedButton(
            onPressed: _save, 
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text("Save & Exit")
          )
        ]
      ),
    );
  }

  Widget _in(String l, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15), 
      child: TextField(
        controller: c, 
        decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())
      )
    );
  }
}
