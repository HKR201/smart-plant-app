import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// တခြားဖိုင်များကို လှမ်းခေါ်ခြင်း
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
  String aqiLevel = '--'; 
  String rainChance = '--%'; 
  List<Map<String, dynamic>> upcomingTasks = []; 

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
      final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$queryCity&appid=$weatherKey&units=metric');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];
        weatherTemp = '${data['main']['temp'].round()}°C';
        weatherDesc = (data['weather'][0]['main']).toString();
        rainChance = data['rain'] != null ? '${data['rain']['1h'] ?? 10}%' : '0%';

        final aqiUrl = Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$weatherKey');
        final aqiResponse = await http.get(aqiUrl);
        if (aqiResponse.statusCode == 200) {
          final aqiData = json.decode(aqiResponse.body);
          aqiLevel = aqiData['list'][0]['main']['aqi'].toString();
        }
      }
    } catch (e) {
      weatherDesc = "အချက်အလက် ယူ၍မရပါ";
    }
    notifyListeners();
  }

  Future<void> loadReminders() async {
    final plants = await DatabaseHelper.instance.getPlants();
    upcomingTasks = [];
    final now = DateTime.now();
    for (var plant in plants) {
      if (plant['saveDate'] == null) continue;
      final saveDate = DateTime.parse(plant['saveDate']);
      if (now.difference(saveDate).inDays >= 3) {
        upcomingTasks.add({'name': plant['name'], 'msg': 'ရေလောင်းရန် အချိန်တန်ပြီ'});
      }
    }
    notifyListeners();
  }

  void incrementSecretTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SecretDoorScreen()));
  }
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('အပင်စောင့်ရှောက်ရေး'), backgroundColor: Colors.green[800], foregroundColor: Colors.white),
      drawer: _buildDrawer(context, state),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWeatherCard(state),
            const SizedBox(height: 20),
            if (state.upcomingTasks.isNotEmpty) ...[
              const Text('သတိပေးချက်များ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...state.upcomingTasks.map((t) => Card(child: ListTile(title: Text(t['name']), subtitle: Text(t['msg']), leading: const Icon(Icons.water_drop, color: Colors.blue)))),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen())),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.green),
              child: const Text('📷 ဓာတ်ပုံရိုက်မည်', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen())),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.orange),
              child: const Text('🖼️ ဓာတ်ပုံပြခန်း', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            GestureDetector(onTap: () => state.incrementSecretTap(context), child: const Center(child: Text('Version 1.1.0', style: TextStyle(color: Colors.grey)))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(state.location, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(state.weatherTemp, style: const TextStyle(fontSize: 40, color: Colors.orange)),
            Text("လေထုအရည်အသွေး (AQI): ${state.aqiLevel}"),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState state) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(decoration: BoxDecoration(color: Colors.green), child: Text('မီနူး', style: TextStyle(color: Colors.white, fontSize: 24))),
          ListTile(leading: const Icon(Icons.inventory), title: const Text('အိမ်ရှိပစ္စည်းစာရင်း'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()))),
          ListTile(leading: const Icon(Icons.book), title: const Text('အကြံဉာဏ်များ'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CareLogsScreen()))),
        ],
      ),
    );
  }
}
