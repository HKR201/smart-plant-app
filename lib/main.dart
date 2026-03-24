import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'action_hub.dart'; 
import 'gallery_screen.dart'; 
import 'secret_door.dart'; 
import 'care_logs.dart';
import 'inventory_screen.dart'; // <--- အသစ်ထည့်လိုက်သော Import
import 'database_helper.dart';

void main() {
  runApp(MultiProvider(providers: [ChangeNotifierProvider(create: (_) => AppState())], child: const SmartPlantApp()));
}

class AppState extends ChangeNotifier {
  Map<String, bool> homeInventory = {'မီးသွေး': false, 'အုတ်မှုန့်': false, 'မြေဆွေး': false, 'ဖွဲပြာ': false, 'သဲ': false};
  String location = 'ရန်ကုန်'; 
  String weatherTemp = '--°C';
  String weatherDesc = '--';

  void toggleInventory(String item) { homeInventory[item] = !homeInventory[item]!; notifyListeners(); }
  void addInventoryItem(String item) { if (item.isNotEmpty) { homeInventory[item] = true; notifyListeners(); } }
  void removeInventoryItem(String item) { homeInventory.remove(item); notifyListeners(); }
  void setLocation(String loc) { location = loc; notifyListeners(); fetchWeather(); }

  Future<void> fetchWeather() async {
    try {
      final p = await SharedPreferences.getInstance();
      final key = p.getString('weather_api_key') ?? '';
      if (key.isEmpty) return;
      final res = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$key&units=metric'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        weatherTemp = '${data['main']['temp'].round()}°C';
        weatherDesc = data['weather'][0]['main'];
        notifyListeners();
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> loadReminders() async { notifyListeners(); }
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(primarySwatch: Colors.green), home: const DashboardScreen());
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
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().fetchWeather());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('အပင်စောင့်ရှောက်ရေး'), backgroundColor: Colors.green[800], foregroundColor: Colors.white),
      drawer: _buildDrawer(context, state),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(child: ListTile(title: Text(state.location, style: const TextStyle(fontSize: 24)), subtitle: Text(state.weatherDesc), trailing: Text(state.weatherTemp, style: const TextStyle(fontSize: 30)))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CameraScreen())), child: const Text('📷 ဓာတ်ပုံရိုက်မည်')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const GalleryScreen())), child: const Text('🖼️ ဓာတ်ပုံပြခန်း')),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SecretDoorScreen())), child: const Center(child: Text('Version 1.1.0', style: TextStyle(color: Colors.grey)))),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState state) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(decoration: BoxDecoration(color: Colors.green), child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24))),
          ListTile(leading: const Icon(Icons.inventory), title: const Text('အိမ်ရှိပစ္စည်းစာရင်း'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const InventoryScreen())); }),
          ListTile(leading: const Icon(Icons.book), title: const Text('အကြံဉာဏ်များ'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const CareLogsScreen())); }),
        ],
      ),
    );
  }
}
