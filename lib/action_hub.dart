import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; 
import 'database_helper.dart'; 

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _controller = CameraController(cameras![0], ResolutionPreset.high);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            isReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ဓာတ်ပုံရိုက်ရန်', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CameraPreview(_controller!),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: SizedBox(
              width: 90,
              height: 90,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final image = await _controller!.takePicture();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalysisScreen(imagePath: image.path),
                      ),
                    );
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.camera_alt, size: 50, color: Colors.green),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AnalysisScreen extends StatefulWidget {
  final String imagePath;
  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String plantName = "အပင်အမည် ရှာဖွေနေပါသည်...";
  String aiAdvice = "";
  bool isLoading = true;
  bool isAdviceLoading = false;

  @override
  void initState() {
    super.initState();
    _identifyPlant(); 
  }

  // ⚠️ Error လုံးဝကင်းစေရန် အဆင့်ဆင့် ခေါ်မည့် (Fallback) လော့ဂျစ်
  Future<GenerateContentResponse> _callGeminiAPI(String apiKey, String promptText) async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final prompt = TextPart(promptText);
    final imagePart = DataPart('image/jpeg', bytes);
    final content = [Content.multi([prompt, imagePart])];

    try {
      // ၁။ ပထမဆုံး အသစ်ဆုံးမော်ဒယ် (gemini-1.5-flash-latest) ဖြင့် စမ်းမည်
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      return await model.generateContent(content);
    } catch (e) {
      // ၂။ အကယ်၍ API Key က အသစ်ကို လက်မခံရင် အသေချာဆုံး အဟောင်းဗားရှင်း (gemini-pro-vision) ကို အလိုအလျောက် ပြောင်းသုံးမည်
      final backupModel = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
      return await backupModel.generateContent(content);
    }
  }

  Future<void> _identifyPlant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key') ?? '';
      final systemPrompt = prefs.getString('system_prompt') ?? 
          "This is an image of a plant. Return only the common Burmese name and its broader category in Burmese format like 'နာမည် - အမျိုးအစား' (e.g., သစ်ခွ - ပန်းပွင့်သောအပင်). Do not include any other text, explanations, or markdown.";

      if (apiKey.isEmpty) {
        setState(() {
          plantName = "⚠️ API Key မထည့်ရသေးပါ (Admin ဆက်တင်တွင် သွားထည့်ပါ)";
          isLoading = false;
        });
        return;
      }

      final response = await _callGeminiAPI(apiKey, systemPrompt);

      setState(() {
        plantName = response.text?.trim() ?? "အမည်မသိအပင် - အခြားအပင်များ";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        plantName = "Error: $e"; 
        isLoading = false;
      });
    }
  }

  Future<void> _askCareAdvice() async {
    setState(() {
      isAdviceLoading = true;
      aiAdvice = "အကြံဉာဏ် တောင်းခံနေပါသည်. ခဏစောင့်ပါ...";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key') ?? '';

      if (apiKey.isEmpty) {
        setState(() {
          aiAdvice = "⚠️ API Key မထည့်ရသေးပါ (Admin ဆက်တင်တွင် သွားထည့်ပါ)";
          isAdviceLoading = false;
        });
        return;
      }

      final state = context.read<AppState>();
      final availableItems = state.homeInventory.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList()
          .join(", ");

      final promptText = "The plant is $plantName. The user has these items available at home: $availableItems. Give simple soil mixing and plant care advice in Burmese using ONLY these available items. Make the explanation very simple and easy to read for an elderly person. No markdown formatting like ** or *.";
      
      final response = await _callGeminiAPI(apiKey, promptText);

      setState(() {
        aiAdvice = response.text?.trim() ?? "အကြံဉာဏ် မရရှိပါ";
        isAdviceLoading = false;
      });
    } catch (e) {
      setState(() {
        aiAdvice = "Advice Error: $e";
        isAdviceLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('အပင်အချက်အလက်', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                File(widget.imagePath),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.green)
                    : Text(
                        plantName.contains("Error") ? plantName : plantName.split('-')[0].trim(), 
                        style: TextStyle(
                          fontSize: plantName.contains("Error") ? 18 : 32, 
                          fontWeight: FontWeight.bold, 
                          color: plantName.contains("Error") ? Colors.red : Colors.green
                        ),
                        textAlign: TextAlign.center,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (aiAdvice.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: const Color(0xFFFFF9C4), 
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    aiAdvice,
                    style: const TextStyle(fontSize: 24, color: Colors.black87, height: 1.5),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: isLoading || isAdviceLoading ? null : _askCareAdvice,
              icon: const Icon(Icons.lightbulb_outline, size: 35),
              label: const Text('ဒီအပင်အကြောင်း သိချင်တယ်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: isLoading ? null : () async {
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final String newPath = '${directory.path}/plant_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  final savedImage = await File(widget.imagePath).copy(newPath);

                  String nameToSave = plantName;
                  String categoryToSave = "အခြားအပင်များ";
                  if (plantName.contains("-")) {
                    final parts = plantName.split("-");
                    nameToSave = parts[0].trim();
                    categoryToSave = parts.length > 1 ? parts[1].trim() : "အခြားအပင်များ";
                  }

                  await DatabaseHelper.instance.insertPlant({
                    'name': nameToSave,
                    'category': categoryToSave,
                    'imagePath': savedImage.path,
                    'advice': aiAdvice.isEmpty ? "" : aiAdvice,
                    'saveDate': DateTime.now().toIso8601String(),
                  });

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ဓာတ်ပုံနှင့် မှတ်တမ်း သိမ်းဆည်းပြီးပါပြီ ✅', style: TextStyle(fontSize: 24))),
                  );
                  Navigator.pop(context); 
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('သိမ်းဆည်းရာတွင် အမှားဖြစ်နေပါသည်: $e', style: const TextStyle(fontSize: 24))),
                  );
                }
              },
              icon: const Icon(Icons.save, size: 35),
              label: const Text('ဓာတ်ပုံသိမ်းမယ်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
