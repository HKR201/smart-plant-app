import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'secret_door.dart';
import 'action_hub.dart';
import 'gallery.dart';

void main() {
  runApp(const SmartPlantApp());
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant Care',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, 
      theme: ThemeData(
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      ),
      darkTheme: ThemeData(
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  List<String> _inventoryList = ["ကြက်ဥခွံ", "ဆန်ဆေးရည်", "အချိုမှုန့်", "မီးသွေး", "မြေဆွေး"];
  List<String> _selectedInventory = [];
  final TextEditingController _itemCtrl = TextEditingController();

  List<String> _cities = ["Yangon", "Mandalay", "Naypyidaw", "Taunggyi"];
  String _selectedCity = "Yangon";
  String _temp = "--";
  String _aqiText = "AQI: --";
  Color _aqiColor = Colors.grey;
  String _rainText = "ရာသီဥတု ယူနေဆဲ...";
  bool _isWeatherLoading = false;
  int _secretCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _inventoryList = prefs.getStringList('inventory') ?? _inventoryList;
      _selectedInventory = prefs.getStringList('selected_inventory') ?? [];
      _cities = prefs.getStringList('cities') ?? _cities;
      _selectedCity = prefs.getString('selected_city') ?? _cities.first;
    });
    _fetchWeather();
  }

  _saveInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('inventory', _inventoryList);
    await prefs.setStringList('selected_inventory', _selectedInventory);
  }

  _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cities', _cities);
    await prefs.setString('selected_city', _selectedCity);
  }

  Future<void> _fetchWeather() async {
    setState(() => _isWeatherLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final weatherKey = prefs.getString('weather_api') ?? '';

    if (weatherKey.isEmpty) {
      setState(() { _temp = "--"; _rainText = "Secret Door တွင် Weather API ထည့်ပါ"; _isWeatherLoading = false; });
      return;
    }
    try {
      final geoUrl = "https://api.openweathermap.org/data/2.5/weather?q=$_selectedCity&appid=$weatherKey&units=metric";
      final geoRes = await http.get(Uri.parse(geoUrl));
      if (geoRes.statusCode == 200) {
        final geoData = jsonDecode(geoRes.body);
        final double lat = geoData['coord']['lat'];
        final double lon = geoData['coord']['lon'];
        final double currentTemp = geoData['main']['temp'];

        final aqiUrl = "https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$weatherKey";
        final forecastUrl = "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$weatherKey";

        // OPTIMIZATION: Fix API Traffic Jam. 
        // Executing both AQI and Forecast APIs CONCURRENTLY instead of sequentially.
        final responses = await Future.wait([
          http.get(Uri.parse(aqiUrl)),
          http.get(Uri.parse(forecastUrl))
        ]);

        final aqiRes = responses[0];
        final forecastRes = responses[1];

        int aqiValue = 0;
        if (aqiRes.statusCode == 200) {
          final aqiData = jsonDecode(aqiRes.body);
          aqiValue = aqiData['list'][0]['main']['aqi']; 
        }

        String rainStatus = "မိုးရွာရန် မရှိပါ";
        if (forecastRes.statusCode == 200) {
          final forecastData = jsonDecode(forecastRes.body);
          // ... (ကျန်တဲ့ မိုးရွာနိုင်ခြေ တွက်တဲ့ for loop ကုဒ်များ မူလအတိုင်း ထားပါ)
          
          final list = forecastData['list'] as List;
          for (var item in list) {
            String mainWeather = item['weather'][0]['main'];
            if (mainWeather.toLowerCase().contains('rain')) {
              DateTime rainTime = DateTime.parse(item['dt_txt']);
              int daysDiff = rainTime.difference(DateTime.now()).inDays;
              if (daysDiff == 0) rainStatus = "၁ ရက်အတွင်း မိုးရွာနိုင်သည်";
              else rainStatus = "$daysDiff ရက်အတွင်း မိုးရွာနိုင်သည်";
              break;
            }
          }
        }
        setState(() {
          _temp = "${currentTemp.round()}°C";
          _aqiText = "AQI: $aqiValue";
          if (aqiValue == 1) _aqiColor = Colors.green;
          else if (aqiValue == 2) _aqiColor = Colors.yellow[700]!;
          else if (aqiValue == 3) _aqiColor = Colors.orange;
          else if (aqiValue >= 4) _aqiColor = Colors.red;
          _rainText = rainStatus;
        });
      } else { setState(() => _rainText = "မြို့အမည် မှားနေပါသည်"); }
    } catch (e) {
      setState(() => _rainText = "အင်တာနက် မရပါ");
    } finally { setState(() => _isWeatherLoading = false); }
  }

  Future<void> _takePhoto(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 30, maxWidth: 800, maxHeight: 800);
    if (photo == null) return;
    setState(() => _isLoading = true);
    try {
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _sendToAI(base64Image, File(photo.path));
    } catch (e) {
      _showError("ဓာတ်ပုံယူလို့ မရပါဘူး: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToAI(String base64Image, File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key')?.trim() ?? '';
    String proxyUrl = prefs.getString('proxy_url')?.trim() ?? '';
    // Secret Door က Model Name ကို လှမ်းယူမယ်
    final modelName = prefs.getString('model_name')?.trim() ?? 'gemini-2.5-flash'; 

    if (apiKey.isEmpty || proxyUrl.isEmpty) { _showError("Secret Door ထဲမှာ API Key နဲ့ Proxy အရင်ထည့်ပေးပါ"); return; }
    
    // Proxy URL နောက်မှာ API Key ရော Model Name ပါ တွဲပို့ပေးမယ်
    if (!proxyUrl.contains('?key=')) {
      proxyUrl = "$proxyUrl?key=$apiKey&model=$modelName";
    } else if (!proxyUrl.contains('&model=')) {
      proxyUrl = "$proxyUrl&model=$modelName";
    }

    final role = prefs.getString('role_box') ?? 'Expert';
    final logic = prefs.getString('logic_box') ?? 'Use Home Inventory items';
    final persona = prefs.getString('persona_box') ?? 'Polite Burmese tone';
    String inventoryText = _selectedInventory.isEmpty ? "None" : _selectedInventory.join(", ");

    final fullPrompt = """
    You MUST strictly follow the instructions below. Return final response as valid JSON only.
    JSON Keys: plant_name, category_tag, display_message.
    [Role]: $role
    [Logic]: $logic
    [Persona]: $persona
    [User Inventory]: $inventoryText
    [Action]: Identify this plant and give advice in Burmese.
    """;

    try {
      final request = http.Request('POST', Uri.parse(proxyUrl))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({"contents": [{"parts": [{"text": fullPrompt}, {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}]}]});

      final client = http.Client();
      var streamedResponse = await client.send(request).timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) response = await client.get(Uri.parse(redirectUrl)).timeout(const Duration(seconds: 60));
      }
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          String rawText = data['candidates'][0]['content']['parts'][0]['text'];
          String cleanedJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
          Map<String, dynamic> finalResult;
          try { finalResult = jsonDecode(cleanedJson); } catch (e) { finalResult = {"plant_name": "အမည်မသိ", "category_tag": "အထွေထွေ", "display_message": cleanedJson}; }
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (c) => ActionHub(image: imageFile, data: finalResult)));
        } else if (data['error'] != null) {
          _showError("AI မှ အဖြေမပေးပါ: ${data['error']['message']}");
        } else { _showError("AI ထံမှ မှန်ကန်သော အဖြေမရရှိပါ"); }
      } else { _showError("Server Error: ${response.statusCode}"); }
    } catch (e) {
      if (e.toString().contains('Timeout')) _showError("အချိန်ကြာမြင့်သွားပါသည် (အင်တာနက် နှေးနေနိုင်သည်)");
      else _showError("Error: $e");
    }
  }
  

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("စိုက်ပျိုးရေး လက်စွဲ", style: TextStyle(fontWeight: FontWeight.w600)),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(), 
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildWeatherWidget(), 
                const Spacer(),
                Text(
                  "အပင်လေးတွေကို\nပြုစုကြရအောင် 🪴", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.onSurface
                  )
                ),
                const Spacer(),
                _minimalButton("ဓာတ်ပုံရိုက်မည်", Icons.camera_alt_rounded, () => _takePhoto(ImageSource.camera), true),
                _minimalButton("ပုံဟောင်းရွေးမည်", Icons.photo_library_rounded, () => _takePhoto(ImageSource.gallery), false),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isLoading) 
            Container(
              color: Colors.black.withOpacity(0.4), 
              child: const Center(
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text("🪴 အပင်လေးကို စစ်ဆေးနေပါသည်...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                )
              )
            ),
        ],
      ),
    );
  }
    // --- UI Polish: Weather Widget ---
  Widget _buildWeatherWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(24), 
      ),
      child: Column(
        children: [
          Row(
            children: [
              _isWeatherLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                : Text(_temp, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_selectedCity, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _aqiColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(_aqiText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: Colors.blue[400], size: 20), 
              const SizedBox(width: 8), 
              Expanded(child: Text(_rainText, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)))
            ]
          )
        ],
      ),
    );
  }

  // --- UI Polish: Sidebar (Drawer) အစီအစဉ်ချခြင်း ---
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), 
              width: double.infinity, 
              child: Text("မီနူး (Menu)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  ExpansionTile(
                    leading: const Icon(Icons.inventory_2_rounded),
                    title: const Text("အိမ်ရှိပစ္စည်းစာရင်း", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Row(
                          children: [
                            Expanded(child: TextField(
                              controller: _itemCtrl, 
                              decoration: InputDecoration(
                                hintText: "ပစ္စည်းအသစ်ထည့်ရန်", 
                                filled: true, 
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15)
                              )
                            )),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () {
                                if (_itemCtrl.text.isNotEmpty) {
                                  setState(() { _inventoryList.add(_itemCtrl.text); _saveInventory(); });
                                  _itemCtrl.clear();
                                }
                              },
                            )
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _inventoryList.length,
                        itemBuilder: (ctx, i) {
                          String item = _inventoryList[i];
                          bool isSelected = _selectedInventory.contains(item);
                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.only(left: 30, right: 10),
                            title: Text(item, style: const TextStyle(fontSize: 15)),
                            value: isSelected,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) _selectedInventory.add(item); else _selectedInventory.remove(item);
                                _saveInventory();
                              });
                            },
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => setState(() { _inventoryList.remove(item); _selectedInventory.remove(item); _saveInventory(); }),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_special_rounded, color: Colors.orange),
                    title: const Text("မှတ်တမ်းများကြည့်မည်", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const SmartGallery()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_city_rounded, color: Colors.blue),
                    title: const Text("ရာသီဥတု မြို့ရွေးမည်", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    onTap: () {
                      Navigator.pop(context); 
                      _showCityManager(); 
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            GestureDetector(
              onTap: () {
                _secretCounter++;
                if (_secretCounter >= 5) { _secretCounter = 0; _askPassword(); }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: Center(
                  child: Text("App Version: 1.0.0", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- UI Polish: Minimalist Button ---
  Widget _minimalButton(String text, IconData icon, VoidCallback onTap, bool isPrimary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 65,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: isPrimary ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: Icon(icon, size: 28),
          label: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          onPressed: onTap,
        ),
      ),
    );
  }

  // --- City Manager Dialog ---
  void _showCityManager() {
    final cityCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("မြို့ ရွေးချယ်ရန်", style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(
                          controller: cityCtrl, 
                          decoration: InputDecoration(
                            hintText: "City (e.g., Yangon)", 
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        )),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () {
                            if (cityCtrl.text.isNotEmpty) {
                              setModalState(() { _cities.add(cityCtrl.text); });
                              setState(() { _saveCities(); });
                              cityCtrl.clear();
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cities.length,
                        itemBuilder: (c, i) {
                          String city = _cities[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(city, style: TextStyle(fontWeight: _selectedCity == city ? FontWeight.bold : FontWeight.normal)),
                            leading: Radio<String>(
                              value: city,
                              groupValue: _selectedCity,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (val) {
                                setState(() { _selectedCity = val!; _saveCities(); _fetchWeather(); });
                                setModalState(() {});
                                Navigator.pop(ctx);
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () { setModalState(() { _cities.removeAt(i); }); setState(() { _saveCities(); }); },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ပိတ်မည်", style: TextStyle(fontWeight: FontWeight.bold)))],
            );
          }
        );
      }
    );
  }

  void _askPassword() {
    final passCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Password"), 
      content: TextField(controller: passCtrl, obscureText: true), 
      actions: [TextButton(onPressed: () { if (passCtrl.text == "1500") { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (c) => const SecretDoor())); } }, child: const Text("Confirm"))]
    ));
  }
}
