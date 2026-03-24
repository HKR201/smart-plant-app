import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isReady = false;

  @override
  void initState() { super.initState(); _init(); }

  _init() async {
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
                child: const Icon(Icons.camera_alt),
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
  const AnalysisScreen({required this.imagePath});
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

  _analyze() async {
    try {
      final p = await SharedPreferences.getInstance();
      final url = p.getString('proxy_url') ?? '';
      final key = p.getString('gemini_api_key') ?? '';
      
      // ... (prompt code stays same) ...

      final response = await http.post(
        Uri.parse('$url/v1beta/models/gemini-1.5-flash:generateContent?key=$key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": fullPrompt}, {"inline_data": {"mime_type": "image/jpeg", "data": base64Encode(bytes)}}]}]
        }),
      );

      // စာသား JSON ဟုတ်မဟုတ် အရင်စစ်မယ်
      if (response.body.contains('Hello World')) {
         setState(() { nameMM = "Error: Proxy ကုဒ် မပြင်ရသေးပါ (Hello World ဖြစ်နေသည်)"; isLoading = false; });
         return;
      }

      final data = jsonDecode(response.body);
      // ... (ကျန်တာ ဆက်သွားမယ်) ...
    } catch (e) { 
      setState(() { nameMM = "Error: JSON ဖတ်၍မရပါ (Proxy Error ဖြစ်နိုင်သည်)"; isLoading = false; }); 
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('အပင်အချက်အလက်')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.file(File(widget.imagePath), height: 300),
            const SizedBox(height: 20),
            Text(nameMM, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
            Text("($nameEN)", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            Text(advice, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            if (!isLoading) ElevatedButton(
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                await File(widget.imagePath).copy(path);
                await DatabaseHelper.instance.insertPlant({'name': "$nameMM ($nameEN)", 'category': 'AI', 'imagePath': path, 'advice': advice, 'saveDate': DateTime.now().toIso8601String()});
                if (mounted) Navigator.pop(context);
              },
              child: const Text('မှတ်တမ်းသိမ်းမည်'),
            )
          ],
        ),
      ),
    );
  }
}
