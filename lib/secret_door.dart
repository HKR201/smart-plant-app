import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretDoorScreen extends StatefulWidget {
  const SecretDoorScreen({super.key});

  @override
  State<SecretDoorScreen> createState() => _SecretDoorScreenState();
}

class _SecretDoorScreenState extends State<SecretDoorScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _weatherKeyController = TextEditingController();
  final TextEditingController _proxyUrlController = TextEditingController();
  
  // Prompt Box ၃ ခု
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _logicController = TextEditingController();
  final TextEditingController _personaController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _weatherKeyController.text = prefs.getString('weather_api_key') ?? '';
      _proxyUrlController.text = prefs.getString('proxy_url') ?? 'https://my-gemini-proxy.youteshin-blog.workers.dev';
      
      _roleController.text = prefs.getString('prompt_role') ?? "မင်းက မြန်မာ့စိုက်ပျိုးရေးပညာရှင် တစ်ယောက်ပါ။";
      _logicController.text = prefs.getString('prompt_logic') ?? "အပင်ကိုခွဲခြားပါ။ အိမ်ရှိပစ္စည်းစာရင်းကို ကြည့်ပြီး လိုအပ်မှသာ ရွေးချယ်အသုံးပြုပါ။ ပစ္စည်းအားလုံးကို အတင်းထည့်မစပ်ပါနဲ့။";
      _personaController.text = prefs.getString('prompt_persona') ?? "လူကြီးတွေကို ပြောသလိုမျိုး ယဉ်ကျေးပျူငှာစွာ ရှင်းပြပေးပါ။";
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    await prefs.setString('weather_api_key', _weatherKeyController.text.trim());
    await prefs.setString('proxy_url', _proxyUrlController.text.trim());
    
    await prefs.setString('prompt_role', _roleController.text.trim());
    await prefs.setString('prompt_logic', _logicController.text.trim());
    await prefs.setString('prompt_persona', _personaController.text.trim());
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဆက်တင်များ သိမ်းဆည်းပြီးပါပြီ ✅')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔒 အဆင့်မြင့် ဆက်တင်များ'), backgroundColor: Colors.black87, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle('🔑 API Keys & Proxy'),
              _buildField(_apiKeyController, 'Gemini API Key'),
              _buildField(_weatherKeyController, 'Weather API Key'),
              _buildField(_proxyUrlController, 'Cloudflare Proxy URL'),
              
              const Divider(height: 40),
              _buildSectionTitle('🧠 AI Brain (Prompt Boxes)'),
              _buildField(_roleController, 'Role (မင်းက ဘယ်သူလဲ)', maxLines: 2),
              _buildField(_logicController, 'Logic (ဘယ်လို စဉ်းစားမလဲ)', maxLines: 4),
              _buildField(_personaController, 'Persona (ဘယ်လို ပြောမလဲ)', maxLines: 2),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.blue[800]),
                child: const Text('သိမ်းဆည်းမည်', style: TextStyle(fontSize: 22, color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
  );

  Widget _buildField(TextEditingController controller, String label, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      style: const TextStyle(fontSize: 18),
    ),
  );
}
