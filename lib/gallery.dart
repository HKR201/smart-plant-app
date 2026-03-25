import 'dart:io';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class SmartGallery extends StatefulWidget {
  const SmartGallery({super.key});

  @override
  State<SmartGallery> createState() => _SmartGalleryState();
}

class _SmartGalleryState extends State<SmartGallery> {
  List<Map<String, dynamic>> _plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  _loadPlants() async {
    final data = await DBHelper.getPlants();
    setState(() {
      _plants = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("မှတ်တမ်းဟောင်းများ 📂", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.withOpacity(0.2),
      ),
      body: _plants.isEmpty
          ? const Center(child: Text("မှတ်တမ်း မရှိသေးပါ", style: TextStyle(fontSize: 24)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _plants.length,
              itemBuilder: (context, index) {
                final plant = _plants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.file(File(plant['image_path']), height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant['plant_name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: Text(plant['category'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 10),
                            Text(plant['message'], style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 10),
                            Text("မှတ်တမ်းတင်ရက်: ${plant['date']}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
