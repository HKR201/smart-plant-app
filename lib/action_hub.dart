import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // AppState ကို လှမ်းယူရန်

// ---------------------------------------------------------
// ၁။ ကင်မရာ ဖွင့်မည့် စာမျက်နှာ
// ---------------------------------------------------------
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
                    // ဓာတ်ပုံရိုက်ပြီးပါက AI ဆီသို့ ပို့ရန် AnalysisScreen သို့ သွားမည်
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

// ---------------------------------------------------------
// ၂။ AI ခွဲခြမ်းစိတ်ဖြာသည့် စာမျက်နှာ (Action Hub)
// ---------------------------------------------------------
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

  // ⚠️ သင့်ရဲ့ Gemini Key ကို ဒီနေရာမှာ အစားထိုးထည့်ပါ။ 
  // ဥပမာ - final String apiKey = "AIzaSyDr2BfqfxlUVlUEWlnfFUkLtGcfmVjuMWw";
  final String apiKey = "YOUR_GEMINI_API_KEY_HERE"; 

  @override
  void initState() {
    super.initState();
    _identifyPlant(); // စာမျက်နှာရောက်တာနဲ့ အပင်အမည်ကို ချက်ချင်းရှာမည်
  }

  // အပင်အမည် ရှာဖွေသည့် လော့ဂျစ်
  Future<void> _identifyPlant() async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final bytes = await File(widget.imagePath).readAsBytes();
      
      final prompt = TextPart("This is an image of a plant. Return only the common Burmese name and its broader category in Burmese (e.g., သစ်ခွ - ပန်းပွင့်သောအပင်). Do not include any other text, explanations, or markdown.");
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      setState(() {
        plantName = response.text?.trim() ?? "အမည်မသိအပင်";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        plantName = "ရှာဖွေ၍မရပါ (အင်တာနက် လိုအပ်ပါသည်)";
        isLoading = false;
      });
    }
  }

  // အိမ်ရှိပစ္စည်းများနှင့် အကြံဉာဏ်တောင်းသည့် လော့ဂျစ်
  Future<void> _askCareAdvice() async {
    setState(() {
      isAdviceLoading = true;
      aiAdvice = "အကြံဉာဏ် တောင်းခံနေပါသည်. ခဏစောင့်ပါ...";
    });

    try {
      final state = context.read<AppState>();
      
      // အိမ်ရှိပစ္စည်းများထဲမှ အမှန်ခြစ်ထားသော ပစ္စည်းများကို စစ်ထုတ်ခြင်း
      final availableItems = state.homeInventory.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList()
          .join(", ");

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final bytes = await File(widget.imagePath).readAsBytes();
      
      final prompt = TextPart("The plant is $plantName. The user has these items available at home: $availableItems. Give simple soil mixing and plant care advice in Burmese using ONLY these available items. Make the explanation very simple and easy to read for an elderly person. No markdown formatting like ** or *.");
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      setState(() {
        aiAdvice = response.text?.trim() ?? "အကြံဉာဏ် မရရှိပါ";
        isAdviceLoading = false;
      });
    } catch (e) {
      setState(() {
        aiAdvice = "အကြံဉာဏ် ရယူ၍မရပါ";
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
            // ရိုက်ထားသော ဓာတ်ပုံ
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
            
            // အပင်အမည် ပြသရန်
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
                        plantName,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI အကြံဉာဏ် ပြသရန် (ခလုတ်နှိပ်မှ ပေါ်မည်)
            if (aiAdvice.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: const Color(0xFFFFF9C4), // အဝါနုရောင်
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    aiAdvice,
                    style: const TextStyle(fontSize: 24, color: Colors.black87, height: 1.5),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // လုပ်ဆောင်ရန် ခလုတ်များ
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
              onPressed: isLoading ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အပင်အသစ်အဖြစ် မှတ်သားပါမည်', style: TextStyle(fontSize: 24))));
              },
              icon: const Icon(Icons.add_circle_outline, size: 35),
              label: const Text('အပင်အသစ်အဖြစ် မှတ်မယ်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: isLoading ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဓာတ်ပုံ သိမ်းဆည်းပါမည်', style: TextStyle(fontSize: 24))));
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
