import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SmartPlantApp());
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant Care',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, 
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
      ),
      home: const Dashboard(),
    );
  }
}

// --- Dashboard Screen ---
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _secretCounter = 0;

  void _checkSecret(BuildContext context) {
    _secretCounter++;
    if (_secretCounter >= 5) {
      _secretCounter = 0;
      _askPassword(context);
    }
  }

  void _askPassword(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("လုံခြုံရေးကုဒ်"),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Password"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (passCtrl.text == "1500") {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const SecretDoor()));
              } else {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ကုဒ်မှားနေပါတယ်")));
              }
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text("☀️ 32°C", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Text("ရန်ကုန်မြို့", style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text("အပင်လေးတွေကို\nပြုစုကြရအောင် 🪴", 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {}, 
                  icon: const Icon(Icons.camera_alt, size: 40),
                  label: const Text("ဓာတ်ပုံရိုက်မည်", style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _checkSecret(context),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("App Version: 1.0.0", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Secret Door Screen ---
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
