import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, colorSchemeSeed: Colors.green),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.green),
      home: const Dashboard(),
    );
  }
}

// --- Dashboard & Logic ---
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePhoto(ImageSource source) async {
    // ဓာတ်ပုံ File Size သေးသွားအောင် imageQuality နဲ့ အရွယ်အစားကို လျှော့ချလိုက်ပါတယ်
    final XFile? photo = await _picker.pickImage(
      source: source, 
      imageQuality: 30, // 50 ကနေ 30 ကို လျှော့ချလိုက်တယ်
      maxWidth: 800,    // ပုံရဲ့ အကျယ်ကို ကန့်သတ်လိုက်တယ်
      maxHeight: 800,   // ပုံရဲ့ အမြင့်ကို ကန့်သတ်လိုက်တယ်
    );
    if (photo == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      await _sendToAI(base64Image, File(photo.path));
    } catch (e) {
      _showError("ဓာတ်ပုံယူလို့ မရပါဘူး: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToAI(String base64Image, File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key') ?? '';
    String proxyUrl = prefs.getString('proxy_url') ?? '';
    
    if (apiKey.isEmpty || proxyUrl.isEmpty) {
      _showError("Secret Door ထဲမှာ API Key နဲ့ Proxy အရင်ထည့်ပေးပါ");
      return;
    }

    // Proxy လမ်းကြောင်းနောက်မှာ Key တွဲပို့ရန်
    if (!proxyUrl.contains('?key=')) {
      proxyUrl = "$proxyUrl?key=$apiKey";
    }

    final role = prefs.getString('role_box') ?? 'Expert Plant Assistant';
    final logic = prefs.getString('logic_box') ?? 'Use Home Inventory items';
    final persona = prefs.getString('persona_box') ?? 'Polite Burmese tone';

    final fullPrompt = """
    You MUST strictly follow the instructions below. Return final response as valid JSON only.
    JSON Keys: plant_name, category_tag, display_message.
    
    [Role]: $role
    [Logic]: $logic
    [Persona]: $persona
    [Action]: Identify this plant and give advice in Burmese.
    """;

    try {
      // 1. Google ဆီ ပို့မည့် Request ကို တည်ဆောက်ခြင်း
      final request = http.Request('POST', Uri.parse(proxyUrl))
        ..followRedirects = false // Google က လမ်းကြောင်းလွှဲရင် App က Error မတက်အောင် တားထားမယ်
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": fullPrompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        });

      // 2. Request ကို စတင်ပို့လွှတ်ခြင်း
      final client = http.Client();
      var streamedResponse = await client.send(request).timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);

      // --- 3. THE MAGIC FIX: 302 Redirect ကို ဖြေရှင်းခြင်း ---
      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          // Google လွှဲပေးတဲ့ လမ်းကြောင်းဆီကနေ အဖြေကို သွားယူမယ်
          response = await client.get(Uri.parse(redirectUrl)).timeout(const Duration(seconds: 30));
        }
      }
      client.close();
      // ----------------------------------------------------

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        String cleanedJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        
        Map<String, dynamic> finalResult;
        try {
          finalResult = jsonDecode(cleanedJson);
        } catch (e) {
          finalResult = {
            "plant_name": "အပင်အမည် မသိရပါ",
            "category_tag": "အထွေထွေ",
            "display_message": cleanedJson
          };
        }

        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (c) => ActionHub(image: imageFile, data: finalResult)
        ));
      } else {
        _showError("Server Error: ${response.statusCode} - ချိတ်ဆက်မှု မှားယွင်းနေပါသည်");
      }
    } catch (e) {
      _showError("ချိတ်ဆက်မှု အဆင်မပြေပါ: $e");
    }
  }
  

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildWeatherWidget(),
                const Expanded(child: Center(child: Text("အပင်လေးတွေကို\nပြုစုကြရအောင် 🪴", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)))),
                _bigButton("📷 ဓာတ်ပုံရိုက်မည်", Colors.green[700]!, () => _takePhoto(ImageSource.camera)),
                const SizedBox(height: 15),
                _bigButton("🖼️ ပုံဟောင်းရွေးမည်", Colors.blue[700]!, () => _takePhoto(ImageSource.gallery)),
                _buildVersionLink(),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: const Row(children: [Text("☀️ 32°C", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)), Spacer(), Text("ရန်ကုန်မြို့", style: TextStyle(fontSize: 20))]),
    );
  }

  Widget _bigButton(String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(width: double.infinity, height: 100, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), onPressed: onTap, child: Text(text, style: const TextStyle(fontSize: 24)))),
    );
  }

  Widget _buildVersionLink() {
    return GestureDetector(onTap: () => _askPassword(context), child: const Padding(padding: EdgeInsets.all(20), child: Text("App Version: 1.0.0", style: TextStyle(color: Colors.grey))));
  }

  void _askPassword(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Password"), content: TextField(controller: passCtrl, obscureText: true), actions: [TextButton(onPressed: () { if (passCtrl.text == "1500") { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (c) => const SecretDoor())); } }, child: const Text("Confirm"))]));
  }
}

// --- Screen 2: Action Hub ---
class ActionHub extends StatelessWidget {
  final File image;
  final Map<String, dynamic> data;

  const ActionHub({super.key, required this.image, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ရလဒ်")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(image, height: 300, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['plant_name'] ?? "အမည်မသိ", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text(data['category_tag'] ?? "အထွေထွေ")),
                  const SizedBox(height: 20),
                  Text(data['display_message'] ?? "အကြံပြုချက် မရှိပါ", style: const TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Secret Door Screen --- (Same as before but simplified for readability)
class SecretDoor extends StatefulWidget {
  const SecretDoor({super.key});
  @override State<SecretDoor> createState() => _SecretDoorState();
}
class _SecretDoorState extends State<SecretDoor> {
  final _keyCtrl = TextEditingController();
  final _proxyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _logicCtrl = TextEditingController();
  final _personaCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }
  _load() async {
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
    if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secret Door")),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _in("Gemini Key", _keyCtrl), _in("Proxy URL", _proxyCtrl), const Divider(),
        _in("Role", _roleCtrl), _in("Logic", _logicCtrl), _in("Persona", _personaCtrl),
        const SizedBox(height: 20), ElevatedButton(onPressed: _save, child: const Text("Save & Exit"))
      ]),
    );
  }
  Widget _in(String l, TextEditingController c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
}
