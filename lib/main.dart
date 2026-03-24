import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'action_hub.dart'; // ကင်မရာစာမျက်နှာကို လှမ်းချိတ်ခြင်း

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const SmartPlantApp(),
    ),
  );
}

// အက်ပ်တစ်ခုလုံးရဲ့ မှတ်ဉာဏ်
class AppState extends ChangeNotifier {
  Map<String, bool> homeInventory = {
    'မီးသွေး': false,
    'အုတ်မှုန့်': false,
    'မြေဆွေး': false,
    'ဖွဲပြာ': false,
    'သဲ': false,
  };

  String location = 'ရန်ကုန်'; 
  int secretTapCount = 0; 

  // ပစ္စည်း အမှန်ခြစ် အတိုး/အလျှော့
  void toggleInventory(String item) {
    homeInventory[item] = !homeInventory[item]!;
    notifyListeners();
  }

  // ပစ္စည်း အသစ်ထည့်ရန်
  void addInventoryItem(String item) {
    if (item.isNotEmpty && !homeInventory.containsKey(item)) {
      homeInventory[item] = true; // အသစ်ထည့်ရင် အလိုအလျောက် အမှန်ခြစ်ထားပေးမည်
      notifyListeners();
    }
  }

  // ပစ္စည်း ဖျက်ရန်
  void removeInventoryItem(String item) {
    homeInventory.remove(item);
    notifyListeners();
  }

  void setLocation(String newLocation) {
    location = newLocation;
    notifyListeners();
  }

  void incrementSecretTap(BuildContext context) {
    secretTapCount++;
    if (secretTapCount >= 5) {
      secretTapCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 လျှို့ဝှက်ဆက်တင်များ ပွင့်ပါပြီ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Plant Care',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFE8F5E9), 
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 24, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ---------------------------------------------------------
// ပင်မ စာမျက်နှာ (Dashboard)
// ---------------------------------------------------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('အပင်စောင့်ရှောက်ရေး', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context, state),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('☀️ ဒီနေ့ နေပူတယ်', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('အပင်လေးတွေ ရေလောင်းဖို့ ကောင်းပါတယ်။', style: TextStyle(fontSize: 24), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: Colors.lightBlue[50],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      '💧 စံပယ်ပင်ကို ရေလောင်းရန် အချိန်တန်ပြီ',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // မကြာမီ ထည့်သွင်းမည့် ကင်မရာ စာမျက်နှာ
              },
              icon: const Icon(Icons.camera_alt, size: 40),
              label: const Text('📷 ဓာတ်ပုံရိုက်မည်', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              
                // မကြာမီ ထည့်သွင်းမည့် ပြခန်း
              },
              icon: const Icon(Icons.photo_library, size: 40),
              label: const Text('🖼️ ဓာတ်ပုံပြခန်း', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.read<AppState>().incrementSecretTap(context),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Version 1.0.0', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState state) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[700]),
            child: const Text('⚙️ ရွေးချယ်ရန်များ', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, size: 35),
            title: const Text('မြို့နယ်ရွေးရန်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            subtitle: Text(state.location, style: const TextStyle(fontSize: 20, color: Colors.blueGrey)),
            onTap: () {},
          ),
          const Divider(thickness: 2),
          // ပစ္စည်းစာရင်းကို အထဲမှာ ဝင်ကြည့်ရအောင် ပြင်ဆင်ထားခြင်း
          ListTile(
            leading: const Icon(Icons.inventory_2, size: 35, color: Colors.brown),
            title: const Text('📦 အိမ်ရှိပစ္စည်းစာရင်း', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // Drawer ကို အရင်ပိတ်မည်
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
            },
          ),
          const Divider(thickness: 2),
          ListTile(
            leading: const Icon(Icons.book, size: 35, color: Colors.blue),
            title: const Text('မှတ်သားထားသော အကြံဉာဏ်များ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, size: 35, color: Colors.red),
            title: const Text('မှတ်တမ်းဖျက်မည်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// သီးသန့် အိမ်ရှိပစ္စည်းစာရင်း စာမျက်နှာ (အသစ်/အဖျက် လုပ်နိုင်သည်)
// ---------------------------------------------------------
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final TextEditingController textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('အိမ်ရှိပစ္စည်းများ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: state.homeInventory.keys.map((String key) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: CheckboxListTile(
              title: Text(key, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              value: state.homeInventory[key],
              onChanged: (bool? value) {
                context.read<AppState>().toggleInventory(key);
              },
              activeColor: Colors.green,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.all(8.0),
              secondary: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 35),
                onPressed: () {
                  context.read<AppState>().removeInventoryItem(key);
                },
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddItemDialog(context, textController);
        },
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, size: 35, color: Colors.white),
        label: const Text('အသစ်ထည့်မည်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ပစ္စည်းအသစ် ထည့်ရန်', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 26),
            decoration: const InputDecoration(
              hintText: 'ဥပမာ - နွားချေး',
              hintStyle: TextStyle(fontSize: 24),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('မလုပ်တော့ပါ', style: TextStyle(fontSize: 24, color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AppState>().addInventoryItem(controller.text);
                controller.clear();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('ထည့်မည်', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
