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

  // --- UI Polish: ဖျက်ခြင်းနှင့် ပြန်ခေါ်ခြင်း (Delete & Undo) ---
  _deletePlant(Map<String, dynamic> plant) async {
    final int id = plant['id'];
    await DBHelper.deletePlant(id); // Database ထဲက ဖျက်မယ်
    
    setState(() {
      _plants.removeWhere((p) => p['id'] == id); // မျက်နှာပြင်ပေါ်ကနေ ဖျက်မယ်
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("မှတ်တမ်းကို ဖျက်လိုက်ပါပြီ"),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "↩️ ပြန်ထားမည်",
          textColor: Colors.orangeAccent,
          onPressed: () async {
            await DBHelper.savePlant(plant); // မှားဖျက်မိရင် Database ထဲ ပြန်ထည့်မယ်
            _loadPlants(); // UI ကို Refresh ပြန်လုပ်မယ်
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("မှတ်တမ်းများ 📂", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _plants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.energy_savings_leaf_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text("မှတ်တမ်း မရှိသေးပါ", style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _plants.length,
              itemBuilder: (context, index) {
                final plant = _plants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0, // Minimalist အရိပ်မပါသော ပုံစံ
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // စာရင်းတိုလေးကို နှိပ်လိုက်လျှင် အသေးစိတ်စာမျက်နှာသို့ သွားမည်
                      Navigator.push(context, MaterialPageRoute(builder: (c) => PlantDetailScreen(plant: plant)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // ဓာတ်ပုံ အသေး (Thumbnail)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(plant['image_path']), 
                              height: 70, width: 70, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(height: 70, width: 70, color: Colors.grey, child: const Icon(Icons.broken_image)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // အပင်နာမည် နှင့် အမျိုးအစား
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plant['plant_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(plant['category'], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          // ဖျက်ရန် ခလုတ် (Trash Icon)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deletePlant(plant),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ------------------------------------------------------------------
// UI Polish: မှတ်တမ်းအသေးစိတ် ပြသမည့် စာမျက်နှာ (Detail View)
// ------------------------------------------------------------------
class PlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plant['plant_name'], style: const TextStyle(fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(File(plant['image_path']), width: double.infinity, height: 350, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(height: 350, color: Colors.grey, child: const Center(child: Icon(Icons.broken_image, size: 50))),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant['plant_name'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Text(plant['category'], style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                  // အကြံပြုချက် စာသားများ
                  Text(plant['message'], style: const TextStyle(fontSize: 20, height: 1.6)),
                  const SizedBox(height: 40),
                  Center(child: Text("မှတ်တမ်းတင်ရက်: ${plant['date']}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                  const SizedBox(height: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
