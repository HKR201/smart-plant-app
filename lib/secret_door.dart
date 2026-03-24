import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretDoorScreen extends StatefulWidget {
  const SecretDoorScreen({super.key});

  @override
  State<SecretDoorScreen> createState() => _SecretDoorScreenState();
}

class _SecretDoorScreenState extends State<SecretDoorScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // သိမ်းထားသော Key နှင့် Prompt ကို ပြန်ခေါ်ခြင်း
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _promptController.text = prefs.getString('system_prompt') ?? 
        "This is an image of a plant. Return only the common Burmese name and its broader category in Burmese format like 'နာမည် - အမျိုးအစား' (e.g., သစ်ခွ - ပန်းပွင့်သောအပင်). Do not include any other text, explanations, or markdown.";
      _isLoading = false;
    });
  }

  // Key နှင့် Prompt ကို ဖုန်းထဲတွင် သိမ်းဆည်းခြင်း
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    await prefs.setString('system_prompt', _promptController.text.trim());
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ဆက်တင်များ သိမ်းဆည်းပြီးပါပြီ ✅', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context); // သိမ်းပြီးရင် နောက်ဆုတ်မည်
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔒 လျှို့ဝှက်ဆက်တင်များ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text('🔑 Gemini API Key ထည့်ရန်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'AIzaSy...',
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),
              
              const Text('📝 AI အတွက် အမိန့်စာ (System Prompt)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 35),
                label: const Text('သိမ်းမည်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
    );
  }
}
