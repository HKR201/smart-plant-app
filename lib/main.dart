import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'action_hub.dart'; 
import 'gallery_screen.dart'; 
import 'secret_door.dart'; 

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

class AppState extends ChangeNotifier {
  Map<String, bool> homeInventory = {
    'မီးသွေး': false,
    'အုတ်မှုန့်': false,
    'မြေဆွေး': false,
    'ဖွဲပြာ': false,
    'သဲ': false,
  };

  String location = 'ရန်ကုန်'; 
  String weatherTemp = '--°C';
  String weatherDesc = 'ရာသီဥတု ရှာဖွေနေပါသည်...';
  int secretTapCount = 0; 

  void toggleInventory(String item) {
    homeInventory[item] = !homeInventory[item]!;
    notifyListeners();
  }

  void addInventoryItem(String item) {
    if (item.isNotEmpty && !homeInventory.containsKey(item)) {
      homeInventory[item] = true;
      notifyListeners();
    }
  }

  void removeInventoryItem(String item) {
    homeInventory.remove(item);
    notifyListeners();
  }

  void setLocation(String newLocation) {
    location = newLocation;
    notifyListeners();
    fetchWeather(); // မြို့ပြောင်းတာနဲ့ ရာသီဥတု အသစ်ပြန်ယူမည်
  }

  // မိုးလေဝသ အချက်အလက် လှမ်းယူသည့် လော့ဂျစ်
  Future<void> fetchWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherKey = prefs.getString('weather_api_key') ?? '';
      
      if (weatherKey.isEmpty) {
        weatherDesc = "⚠️ Weather API Key မထည့်ရသေးပါ";
        notifyListeners();
        return;
      }

      final Map<String, String> cityMap = {
        'ရန်ကုန်': 'Yangon',
        'မန္တလေး': 'Mandalay',
        'နေပြည်တော်': 'Naypyidaw',
        'တောင်ကြီး': 'Taunggyi',
        'ပုသိမ်': 'Pathein',
        'ပဲခူး': 'Bago',
      };

      final queryCity = cityMap[location] ?? 'Yangon';
      final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$queryCity&appid=$weatherKey&units=metric');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['main']['temp'].round().toString();
        final mainDesc = data['weather'][0]['main'].toString().toLowerCase();

        weatherTemp = '$temp°C';

        if (mainDesc.contains('cloud')) {
          weatherDesc = 'တိမ်ထူထပ်နေပါသည် ☁️';
        } else if (mainDesc.contains('rain')) {
          weatherDesc = 'မိုးရွာနိုင်ပါသည် 🌧️';
        } else if (mainDesc.contains('clear')) {
          weatherDesc = 'နေသာပါသည် ☀️';
        } else {
          weatherDesc = 'ရာသီဥတု သာယာပါသည် 🌤️';
        }
      } else {
        weatherDesc = "ရာသီဥတု ယူ၍မရပါ";
      }
    } catch (e) {
      weatherDesc = "အင်တာနက် ချိတ်ဆက်မှု မရှိပါ";
    }
    notifyListeners();
  }

  void incrementSecretTap(BuildContext context) {
    secretTapCount++;
    if (secretTapCount >= 5) {
      secretTapCount = 0; 
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SecretDoorScreen()));
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
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // အက်ပ်စပွင့်တာနဲ့ ရာသီဥတုကို တစ်ခါတည်း လှမ်းယူမည်
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchWeather();
    });
  }

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
            // ရာသီဥတု ပြသမည့် ကတ်
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('${state.location} မြို့ အခြေအနေ', style: const TextStyle(fontSize: 22, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(state.weatherTemp, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 10),
                    Text(state.weatherDesc, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()));
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
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
            leading: const Icon(Icons.location_on, size: 35, color: Colors.blue),
            title: const Text('မြို့နယ်ရွေးရန်', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            subtitle: Text(state.location, style: const TextStyle(fontSize: 20, color: Colors.blueGrey)),
            onTap: () {
              Navigator.pop(context); // Drawer ကို အရင်ပိတ်မည်
              _showLocationDialog(context);
            },
          ),
          const Divider(thickness: 2),
          ListTile(
            leading: const Icon(Icons.inventory_2, size: 35, color: Colors.brown),
            title: const Text('📦 အိမ်ရှိပစ္စည်းစာရင်း', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); 
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

  // မြို့နယ် ရွေးချယ်မည့် Box
  void _showLocationDialog(BuildContext context) {
    final List<String> cities = ['ရန်ကုန်', 'မန္တလေး', 'နေပြည်တော်', 'တောင်ကြီး', 'ပုသိမ်', 'ပဲခူး'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('မြို့ကို ရွေးချယ်ပါ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: cities.map((city) {
                return ListTile(
                  title: Text(city, style: const TextStyle(fontSize: 24)),
                  onTap: () {
                    context.read<AppState>().setLocation(city);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

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
            decoration: const InputDecoration(hintText: 'ဥပမာ - နွားချေး', hintStyle: TextStyle(fontSize: 24)),
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
