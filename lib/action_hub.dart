import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; 
import 'database_helper.dart'; 

// --- [Note: CameraScreen remains identical to previous version] ---
// ... (Insert CameraScreen here if copying full file) ...

class AnalysisScreen extends StatefulWidget {
  final String imagePath;
  const AnalysisScreen({super.key, required this.imagePath});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String plantNameMM = "ရှာဖွေနေပါသည်...";
  String plantNameEN = "";
  String aiAdvice = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _identifyPlant(); 
  }

  Future<void> _identifyPlant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key') ?? '';
      final proxyUrl = prefs.getString('proxy_url') ?? '';
      
      final role = prefs.getString('prompt_role') ?? '';
      final logic = prefs.getString('prompt_logic') ?? '';
      final persona = prefs.getString('prompt_persona') ?? '';

      final state = context.read<AppState>();
      final inventory = state.homeInventory.entries.where((e) => e.value).map((e) => e.key).join(", ");

      if (apiKey.isEmpty || proxyUrl.isEmpty) {
        setState(() { plantNameMM = "⚠️ API Key/Proxy လိုအပ်ပါသည်"; isLoading = false; });
        return;
      }

      // JSON structure ထဲမှာ plant_name_english ကို ထပ်တိုးလိုက်ပါတယ်
      final fullPrompt = """
[Hidden System Directive]
Return strictly as a valid JSON object.
JSON keys: plant_name_burmese, plant_name_english, category_tag, display_message.

[User Persona Instructions]
Role: $role
Logic: $logic
Persona: $persona

[Context Data]
Inventory: $inventory
Action: Analyze this plant image. Provide the Burmese common name and its English common name or scientific name.
""";

      final bytes = await File(widget.imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('$proxyUrl/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [
              {"text": fullPrompt},
              {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
            ]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonRes = jsonDecode(rawText);

        setState(() {
          plantNameMM = jsonRes['plant_name_burmese'] ?? "အမည်မသိ";
          plantNameEN = jsonRes['plant_name_english'] ?? "";
          aiAdvice = jsonRes['display_message'] ?? "";
          isLoading = false;
        });
      } else {
        throw Exception("Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() { plantNameMM = "Error: $e"; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('အပင်အချက်အလက်'), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(widget.imagePath), height: 280, fit: BoxFit.cover)),
            const SizedBox(height: 20),
            
            // --- အပင်နာမည်များကို MM (EN) ပုံစံဖြင့် ပြသခြင်း ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (isLoading) const CircularProgressIndicator()
                    else ...[
                      Text(plantNameMM, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
                      if (plantNameEN.isNotEmpty)
                        Text("($plantNameEN)", style: const TextStyle(fontSize: 20, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),

            if (aiAdvice.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(color: const Color(0xFFFFF9C4), child: Padding(padding: const EdgeInsets.all(20), child: Text(aiAdvice, style: const TextStyle(fontSize: 22, height: 1.5)))),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () async {
                final directory = await getApplicationDocumentsDirectory();
                final String newPath = '${directory.path}/plant_${DateTime.now().millisecondsSinceEpoch}.jpg';
                await File(widget.imagePath).copy(newPath);
                await DatabaseHelper.instance.insertPlant({
                  'name': "$plantNameMM ($plantNameEN)",
                  'category': 'AI Scan',
                  'imagePath': newPath,
                  'advice': aiAdvice,
                  'saveDate': DateTime.now().toIso8601String(),
                });
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.save, size: 30),
              label: const Text('မှတ်တမ်းသိမ်းမည်', style: TextStyle(fontSize: 22)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15), backgroundColor: Colors.green[800], foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
