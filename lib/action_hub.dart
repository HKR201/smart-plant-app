import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() => _isReady = true);
    }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: FloatingActionButton(
                onPressed: () async {
                  final img = await _controller!.takePicture();
                  if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnalysisScreen(imagePath: img.path)));
                },
                child: const Icon(Icons.camera),
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
  String nameMM = "ရှာဖွေနေပါသည်...";
  String nameEN = "";
  String advice = "";
  bool isLoading = true;

  @override
  void initState() { super.initState(); _analyze(); }

  Future<void> _analyze() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('proxy_url') ?? '';
      final key = prefs.getString('gemini_api_key') ?? '';
      
      final prompt = """
      Return ONLY valid JSON.
      Keys: plant_name_burmese, plant_name_english, display_message.
      Role: ${prefs.getString('prompt_role')}
      Logic: ${prefs.getString('prompt_logic')}
      """;

      final bytes = await File(widget.imagePath).readAsBytes();
      final response = await http.post(
        Uri.parse('$url/v1beta/models/gemini-1.5-flash:generateContent?key=$key'),
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}, {"inline_data": {"mime_type": "image/jpeg", "data": base64Encode(bytes)}}]}]
        }),
      );

      final data = jsonDecode(response.body);
      String cleanJson = data['candidates'][0]['content']['parts'][0]['text'].replaceAll('```json', '').replaceAll('```', '').trim();
      final result = jsonDecode(cleanJson);

      setState(() {
        nameMM = result['plant_name_burmese'];
        nameEN = result['plant_name_english'];
        advice = result['display_message'];
        isLoading = false;
      });
    } catch (e) { setState(() { nameMM = "Error: $e"; isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ရလဒ်')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.file(File(widget.imagePath), height: 300),
            Text(nameMM, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text("($nameEN)", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            Text(advice, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                final path = '${dir.path}/${DateTime.now().ms}.jpg';
                await File(widget.imagePath).copy(path);
                await DatabaseHelper.instance.insertPlant({'name': nameMM, 'category': 'AI', 'imagePath': path, 'advice': advice, 'saveDate': DateTime.now().toIso8601String()});
                if (mounted) Navigator.pop(context);
              },
              child: const Text('သိမ်းမည်'),
            )
          ],
        ),
      ),
    );
  }
}

extension on DateTime { int get ms => millisecondsSinceEpoch; }
