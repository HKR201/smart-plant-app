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
      title: 'Plant Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // ဖုန်း Setting အတိုင်း Dark/Light ပြောင်းမယ်
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _tapCount = 0;

  void _handleSecretDoor(BuildContext context) {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      _showPasswordDialog(context);
    }
  }

  void _showPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("လုံခြုံရေး ကုဒ်ရိုက်ထည့်ပါ"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Password"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text == "1500") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SecretDoorPage()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password မှားယွင်းနေပါသည်")));
              }
            },
            child: const Text("ဝင်မည်"),
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
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("မင်္ဂလာပါ ဖိုးဖိုး ဖွားဖွား 🪴", style: TextStyle(fontSize: 30)),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bigButton("📷 ဓာတ်ပုံရိုက်မည်", Colors.green, () {}),
                    const SizedBox(height: 20),
                    _bigButton("🖼️ ပုံဟောင်းများကြည့်မည်", Colors.blue, () {}),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _handleSecretDoor(context),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("App Version: 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 300,
      height: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class SecretDoorPage extends StatefulWidget {
  const SecretDoorPage({super.key});

  @override
  State<SecretDoorPage> createState() => _SecretDoorPageState();
}

class _SecretDoorPageState extends State<SecretDoorPage> {
  final _keyCtrl = TextEditingController();
  final _proxyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keyCtrl.text = prefs.getString('api_key') ?? '';
      _proxyCtrl.text = prefs.getString('proxy_url') ?? '';
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _keyCtrl.text);
    await prefs.setString('proxy_url', _proxyCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("သိမ်းဆည်းပြီးပါပြီ")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secret Door Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _keyCtrl, decoration: const InputDecoration(labelText: "Gemini API Key")),
              const SizedBox(height: 20),
              TextField(controller: _proxyCtrl, decoration: const InputDecoration(labelText: "Cloudflare Proxy URL")),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _saveSettings, child: const Text("Save Settings")),
            ],
          ),
        ),
      ),
    );
  }
}
