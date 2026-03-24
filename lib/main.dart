import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'action_hub.dart'; 
import 'gallery_screen.dart'; 
import 'secret_door.dart'; 
import 'care_logs.dart';
import 'database_helper.dart';

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
    'မီးသွေး': false, 'အုတ်မှုန့်': false, 'မြေဆွေး': false, 'ဖွဲပြာ': false, 'သဲ': false,
  };

  String location = 'ရန်ကုန်'; 
  String weatherTemp = '--°C';
  String weatherDesc = 'ရှာဖွေနေပါသည်...';
  String aqiLevel = '--'; // AQI အဆင့်
  String rainChance = '--%'; // မိုးရွာနိုင်ခြေ
  List<Map<String, dynamic>> upcomingTasks = []; // သတိပေးချက်စာရင်း

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
    fetchWeather(); 
  }

  // --- အဆင့်မြှင့်ထားသော မိုးလေဝသ လော့ဂျစ် ---
  Future<void> fetchWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherKey = prefs.getString('weather_api_key') ?? '';
      if (weatherKey.isEmpty) {
        weatherDesc = "API Key လိုအပ်ပါသည်";
        notifyListeners();
        return;
      }

      final Map<String, String> cityMap = {
        'ရန်ကုန်': 'Yangon', 'မန္တလေး': 'Mandalay', 'နေပြည်တော်': 'Naypyidaw',
        'တောင်ကြီး': 'Taunggyi', 'ပုသိမ်': 'Pathein', 'ပဲခူး': 'Bago',
      };
      final queryCity = cityMap[location] ?? 'Yangon';

      // ၁။ ရိုးရိုး မိုးလေဝသ ယူခြင်း
      final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$queryCity&appid=$weatherKey&units=metric');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];
        weatherTemp = '${data['main']['temp'].round()}°C';
        weatherDesc = _translateWeather(data['weather'][0]['main']);
        rainChance = data['rain'] != null ? '${data['rain']['1h'] ?? 10}%' : '0%';

        // ၂။ AQI (လေထုအရည်အသွေး) ထပ်ယူခြင်း
        final aqiUrl = Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$weatherKey');
        final aqiResponse = await http.get(aqiUrl);
        if (aqiResponse.statusCode == 200) {
          final aqiData = json.decode(aqiResponse.body);
          aqiLevel = _translateAQI(aqiData['list'][0]['main']['aqi']);
        }
      }
    } catch (e) {
      weatherDesc = "အချက်အလက် ယူ၍မရပါ";
    }
    notifyListeners();
  }

  String _translateWeather(String desc) {
    desc = desc.toLowerCase();
    if (desc.contains('cloud')) return 'တိမ်ထူထပ်မည် ☁️';
    if (desc.contains('rain')) return 'မိုးရွာနိုင်သည် 🌧️';
    if (desc.contains('clear')) return 'နေသာပါသည် ☀️';
    return 'သာယာပါသည် 🌤️';
  }

  String _translateAQI(int level) {
    switch (level) {
      case 1: return "ကောင်းမွန် ✅";
      case 2: return "သင့်တင့် 🆗";
      case 3: return "မကောင်းပါ ⚠️";
      case 4: return "ဆိုးရွား ❌";
      case 5: return "အန္တရာယ်ရှိ 🆘";
      default: return "--";
    }
  }

  // --- သတိပေးချက် (Reminders) လော့ဂျစ် ---
  Future<void> loadReminders() async {
    final plants = await DatabaseHelper.instance.getPlants();
    upcomingTasks = [];
    final now = DateTime.now();

    for (var plant in plants) {
      // သိမ်းထားတဲ့ရက်ကနေ ၃ ရက်ကျော်ရင် ရေလောင်းဖို့ သတိပေးမယ် (ရိုးရှင်းသော လော့ဂျစ်)
      final saveDate = DateTime.parse(plant['saveDate']);
      final diff = now.difference(saveDate).inDays;
      if (diff >= 3) {
        upcomingTasks.add({
          'name': plant['name'],
          'msg': 'ရေလောင်းရန် အချိန်တန်ပြီ',
          'icon': Icons.opacity
        });
      }
    }
    notifyListeners();
  }

  int secretTapCount = 0;
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
      theme: ThemeData(primarySwatch: Colors.green, scaffoldBackgroundColor: const Color(0xFFF1F8E9)),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchWeather();
      context.read<AppState>().loadReminders();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "မင်္ဂလာနံနက်ခင်းပါ 🌅";
    if (hour < 17) return "မင်္ဂလာနေ့လယ်ခင်းပါ ☀️";
    return "မင်္ဂလာညချမ်းပါ 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('အပင်စောင့်ရှောက်ရေး', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, state),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_getGreeting(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 15),
            
            // --- Advanced Weather Widget ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.location, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(state.weatherDesc, style: const TextStyle(fontSize: 20, color: Colors.blueGrey)),
                        ],
                      ),
                      Text(state.weatherTemp, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _weatherInfo('လေထု (AQI)', state.aqiLevel),
                      _weatherInfo('မိုးရွာနိုင်ခြေ', state.rainChance),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Smart Reminders Area ---
            const Text('လုပ်ဆောင်ရန်များ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (state.upcomingTasks.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('ယနေ့အတွက် လုပ်ဆောင်ရန် မရှိပါ ✨', style: TextStyle(fontSize: 20, color: Colors.grey), textAlign: TextAlign.center),
                ),
              )
            else
              ...state.upcomingTasks.map((task) => Card(
                color: Colors.blue[50],
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(task['icon'], color: Colors.blue, size: 35),
                  title: Text(task['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle: Text(task['msg'], style: const TextStyle(fontSize: 18)),
                ),
              )),

            const SizedBox(height: 20),
            _actionButton(context, '📷 ဓာတ်ပုံရိုက်မည်', Colors.green[600]!, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()));
            }),
            const SizedBox(height: 15),
            _actionButton(context, '🖼️ ဓာတ်ပုံပြခန်း', Colors.orange[600]!, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
            }),
            
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => state.incrementSecretTap(context),
              child: const Center(child: Text('Version 1.1.0', style: TextStyle(color: Colors.grey))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState state) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[800]),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text('ရွေးချယ်ရန်များ', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _drawerItem(Icons.location_on, 'မြို့နယ်ရွေးရန်', state.location, () {
            Navigator.pop(context);
            _showLocationDialog(context);
          }),
          _drawerItem(Icons.inventory_2, '📦 အိမ်ရှိပစ္စည်းစာရင်း', 'ပစ္စည်းများ ထည့်သွင်းရန်', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
          }),
          _drawerItem(Icons.book, 'မှတ်သားထားသော အကြံဉာဏ်များ', 'ယခင်မှတ်တမ်းများ', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CareLogsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 35, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 18)),
      onTap: onTap,
    );
  }

  void _showLocationDialog(BuildContext context) {
    final List<String> cities = ['ရန်ကုန်', 'မန္တလေး', 'နေပြည်တော်', 'တောင်ကြီး', 'ပုသိမ်', 'ပဲခူး'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('မြို့ကို ရွေးချယ်ပါ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cities.map((c) => ListTile(
            title: Text(c, style: const TextStyle(fontSize: 22)),
            onTap: () {
              context.read<AppState>().setLocation(c);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}
