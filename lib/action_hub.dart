import 'dart:io';
import 'package:flutter/material.dart';

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
                  Text(
                    data['plant_name'] ?? "အမည်မသိ", 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2), 
                      borderRadius: BorderRadius.circular(10)
                    ), 
                    child: Text(data['category_tag'] ?? "အထွေထွေ")
                  ),
                  const SizedBox(height: 20),
                  Text(
                    data['display_message'] ?? "အကြံပြုချက် မရှိပါ", 
                    style: const TextStyle(fontSize: 22)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
