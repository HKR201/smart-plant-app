import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

// အက်ပ်တစ်ခုလုံးရဲ့ မှတ်ဉာဏ်ထိန်းချုပ်မည့်နေရာ (State Management)
class AppState extends ChangeNotifier {
  // အိမ်ရှိပစ္စည်းများ (Inventory) မှတ်သားထားရန်
  Map<String, bool> homeInventory = {
    'မီးသွေး': false,
    'အုတ်မှုန့်': false,
    'မြေဆွေး': false,
    'ဖွဲပြာ': false,
    'သဲ': false,
  };

  String location = 'ရန်ကုန်'; // မိုးလေဝသအတွက် မြို့အမည်
  int secretTapCount = 0; // လျှို့ဝှက်တံခါးအတွက် အကြိမ်အရေအတွက်

  void toggleInventory(String item) {
    homeInventory[item] = !homeInventory[item]!;
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
      // လျှို့ဝှက်တံခါးပွင့်ကြောင်း ပြသခြင်း (Admin စာမျက်နှာကို နောက်ပိုင်းချိတ်ဆက်မည်)
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
        scaffoldBackgroundColor: const Color(0xFFE8F5E9), // မျက်စိရှင်းသော အစိမ်းနုရောင် နောက်ခံ
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

// ပင်မ စာမျက်နှာ (Dashboard)
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
            // အပေါ်ပိုင်း - မိုးလေဝသ နှင့် အကြံပြုချက်
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

            // အလယ်ပိုင်း - သတိပေးချက်များ
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

            // အောက်ပိုင်း - အသုံးပြုရလွယ်ကူသော ခလုတ်ကြီးများ
            ElevatedButton.icon(
              onPressed: () {
                // ကင်မရာစာမျက်နှာသို့ သွားရန် (Action Hub)
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
                // ပြခန်းစာမျက်နှာသို့ သွားရန် (Gallery)
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
            
            // လျှို့ဝှက်တံခါး ဖွင့်ရန် နေရာ (Version Text)
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

  // ဘေးတိုက်ဆွဲထုတ်နိုင်သော မီနူး (Drawer)
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
            onTap: () {
              // မြို့ပြောင်းရန် (နောက်ပိုင်းထည့်မည်)
            },
          ),
          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('📦 အိမ်ရှိပစ္စည်းစာရင်း', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          ...state.homeInventory.keys.map((String key) {
            return CheckboxListTile(
              title: Text(key, style: const TextStyle(fontSize: 24)),
              value: state.homeInventory[key],
              onChanged: (bool? value) {
                context.read<AppState>().toggleInventory(key);
              },
              activeColor: Colors.green,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            );
          }),
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
