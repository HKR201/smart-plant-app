import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, dynamic>> allPlants = [];
  Map<String, List<Map<String, dynamic>>> groupedPlants = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await DatabaseHelper.instance.getPlants();
    
    // အပင်များကို အမျိုးအစား (Category) အလိုက် ဖိုင်တွဲခွဲခြင်း
    Map<String, List<Map<String, dynamic>>> tempGroup = {};
    for (var plant in plants) {
      String category = plant['category'] ?? 'အခြားအပင်များ';
      if (!tempGroup.containsKey(category)) {
        tempGroup[category] = [];
      }
      tempGroup[category]!.add(plant);
    }

    setState(() {
      allPlants = plants;
      groupedPlants = tempGroup;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🖼️ ဓာတ်ပုံပြခန်း', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : allPlants.isEmpty
              ? _buildEmptyState()
              : _buildFolderView(),
    );
  }

  // မှတ်တမ်း မရှိသေးချိန်တွင် ပြသမည့် ပုံစံ
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_album_outlined, size: 100, color: Colors.orange[300]),
          const SizedBox(height: 20),
          const Text('မှတ်တမ်း မရှိသေးပါ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          const Text('ကင်မရာဖြင့် ဓာတ်ပုံရိုက်၍ မှတ်သိမ်းပါ', style: TextStyle(fontSize: 22, color: Colors.grey)),
        ],
      ),
    );
  }

  // ဖိုင်တွဲ (Folders) များ ပြသမည့် ပုံစံ
  Widget _buildFolderView() {
    final categories = groupedPlants.keys.toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        String categoryName = categories[index];
        int plantCount = groupedPlants[categoryName]!.length;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: const Icon(Icons.folder, size: 60, color: Colors.orange),
            title: Text(categoryName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            subtitle: Text('$plantCount ပင် မှတ်သားထားသည်', style: const TextStyle(fontSize: 22, color: Colors.blueGrey)),
            onTap: () {
              // ဖိုင်တွဲထဲ ဝင်ကြည့်မည်
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(
                    categoryName: categoryName,
                    plants: groupedPlants[categoryName]!,
                  ),
                ),
              ).then((_) => _loadPlants()); // ပြန်ထွက်လာရင် အချက်အလက် ပြန်စစ်မည်
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// ဖိုင်တွဲအတွင်းရှိ ဓာတ်ပုံများကို အသေးစိတ်ပြသမည့် စာမျက်နှာ
// ---------------------------------------------------------
class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> plants;

  const CategoryDetailScreen({super.key, required this.categoryName, required this.plants});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 20.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.file(
                    File(plant['imagePath']),
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plant['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 10),
                      if (plant['advice'] != null && plant['advice'].toString().isNotEmpty)
                        Text(plant['advice'], style: const TextStyle(fontSize: 22, color: Colors.black87)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 35, color: Colors.red),
                          onPressed: () async {
                            // အပင်ဖျက်ရန်
                            await DatabaseHelper.instance.deletePlant(plant['id']);
                            Navigator.pop(context); // ဖျက်ပြီးပါက နောက်ပြန်ဆုတ်မည်
                          },
                        ),
                      )
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
