import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'db_helper.dart';

class ActionHub extends StatefulWidget {
  final File image;
  final Map<String, dynamic> data;

  const ActionHub({super.key, required this.image, required this.data});

  @override
  State<ActionHub> createState() => _ActionHubState();
}

class _ActionHubState extends State<ActionHub> {
  bool _isSaved = false;

  _saveRecord() async {
    try {
      // 1. ပုံကို ဖုန်းရဲ့ လုံခြုံတဲ့ နေရာကို ကူးယူသိမ်းဆည်းခြင်း
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(widget.image.path);
      final savedImage = await widget.image.copy('${appDir.path}/$fileName');

      // 2. Database ထဲကို စာသားတွေနဲ့ ပုံလမ်းကြောင်း ထည့်သွင်းခြင်း
      await DBHelper.savePlant({
        'plant_name': widget.data['plant_name'] ?? "အမည်မသိ",
        'category': widget.data['category_tag'] ?? "အထွေထွေ",
        'message': widget.data['display_message'] ?? "",
        'image_path': savedImage.path,
        'date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD
      });

      setState(() { _isSaved = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("သိမ်းဆည်းရန် မအောင်မြင်ပါ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ရလဒ်")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(widget.image, height: 300, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['plant_name'] ?? "အမည်မသိ", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text(widget.data['category_tag'] ?? "အထွေထွေ")),
                  const SizedBox(height: 20),
                  Text(widget.data['display_message'] ?? "အကြံပြုချက် မရှိပါ", style: const TextStyle(fontSize: 22)),
                  
                  const SizedBox(height: 30),
                  // သိမ်းဆည်းရန် ခလုတ်အကြီး
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaved ? Colors.grey : Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: _isSaved ? null : _saveRecord,
                      icon: Icon(_isSaved ? Icons.check_circle : Icons.save, size: 30),
                      label: Text(_isSaved ? "သိမ်းဆည်းပြီးပါပြီ" : "💾 မှတ်တမ်းသိမ်းမည်", style: const TextStyle(fontSize: 24)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
