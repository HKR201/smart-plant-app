import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// ခုနက ခွဲထုတ်လိုက်တဲ့ ဖိုင် ၂ ခုကို လှမ်းချိတ်လိုက်တာပါ
import 'secret_door.dart';
import 'action_hub.dart';

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
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, colorSchemeSeed: Colors.green),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.green),
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

  // Inventory
  List<String> _inventoryList = ["ကြက်ဥခွံ", "ဆန်ဆေးရည်", "အချိုမှုန့်", "မီးသွေး", "မြေဆွေး"];
  List<String> _selectedInventory = [];
  final TextEditingController _itemCtrl = TextEditingController();

  // Weather
  List<String> _cities = ["Yangon", "Mandalay", "Naypyidaw"];
  String _selectedCity = "Yangon";
  String _temp = "--";
  String _aqiText = "AQI: --";
  Color _aqiColor = Colors.grey;
  String _rainText = "ရာသီဥတု ယူနေဆဲ...";
  bool _isWeatherLoading = false;

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
      setState(() {
        _temp = "--";
        _rainText = "Secret Door တွင် Weather API ထည့်ပါ";
        _isWeatherLoading = false;
      });
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
        final aqiRes = await http.get(Uri.parse(aqiUrl));
        int aqiValue = 0;
        if (aqiRes.statusCode == 200) {
          final aqiData = jsonDecode(aqiRes.body);
          aqiValue = aqiData['list'][0]['main']['aqi']; 
        }

        final forecastUrl = "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$weatherKey";
        final forecastRes = await http.get(Uri.parse(forecastUrl));
        String rainStatus = "မိုးရွာရန် မရှိပါ";
        if (forecastRes.statusCode == 200) {
          final forecastData = jsonDecode(forecastRes.body);
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
      } else {
        setState(() => _rainText = "မြို့အမည် မှားနေပါသည်");
      }
    } catch (e) {
      setState(() => _rainText = "အင်တာနက် မရပါ");
    } finally {
      setState(() => _isWeatherLoading = false);
    }
  }

  void _showCityManager() {
    final cityCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("မြို့ ရွေးချယ်ရန်"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(hintText: "City (e.g., Yangon)"))),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
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
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cities.length,
                        itemBuilder: (c, i) {
                          String city = _cities[i];
                          return ListTile(
                            title: Text(city, style: TextStyle(fontWeight: _selectedCity == city ? FontWeight.bold : FontWeight.normal)),
                            leading: Radio<String>(
                              value: city,
                              groupValue: _selectedCity,
                              onChanged: (val) {
                                setState(() { _selectedCity = val!; _saveCities(); _fetchWeather(); });
                                setModalState(() {});
                                Navigator.pop(ctx);
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setModalState(() { _cities.removeAt(i); });
                                setState(() { _saveCities(); });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ပိတ်မည်"))],
            );
          }
        );
      }
    );
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
      _showError("ဓာတ်ပုံယူလို့ မရပါဘူး");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToAI(String base64Image, File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key') ?? '';
    String proxyUrl = prefs.getString('proxy_url') ?? '';
    
    if (apiKey.isEmpty || proxyUrl.isEmpty) {
      _showError("Secret Door ထဲမှာ API Key နဲ့ Proxy အရင်ထည့်ပေးပါ");
      return;
    }

    if (!proxyUrl.contains('?key=')) proxyUrl = "$proxyUrl?key=$apiKey";

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
      var streamedResponse = await client.send(request).timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) response = await client.get(Uri.parse(redirectUrl)).timeout(const Duration(seconds: 30));
      }
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        String cleanedJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        Map<String, dynamic> finalResult;
        try { 
          finalResult = jsonDecode(cleanedJson); 
        } catch (e) { 
          finalResult = {"plant_name": "အမည်မသိ", "category_tag": "အထွေထွေ", "display_message": cleanedJson}; 
        }

        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (c) => ActionHub(image: imageFile, data: finalResult)));
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("ချိတ်ဆက်မှု အဆင်မပြေပါ");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("စိုက်ပျိုးရေး လက်စွဲ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.withOpacity(0.2),
        elevation: 0,
      ),
      drawer: _buildDrawer(), 
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildWeatherWidget(),
                const Expanded(child: Center(child: Text("အပင်လေးတွေကို\nပြုစုကြရအောင် 🪴", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)))),
                _bigButton("📷 ဓာတ်ပုံရိုက်မည်", Colors.green[700]!, () => _takePhoto(ImageSource.camera)),
                const SizedBox(height: 15),
                _bigButton("🖼️ ပုံဟောင်းရွေးမည်", Colors.blue[700]!, () => _takePhoto(ImageSource.gallery)),
                _buildVersionLink(),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return GestureDetector(
      onTap: _showCityManager,
      child: Container(
        margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
        child: Column(
          children: [
            Row(
              children: [
                _isWeatherLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : Text(_temp, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_selectedCity, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _aqiColor, borderRadius: BorderRadius.circular(5)),
                      child: Text(_aqiText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.water_drop, color: Colors.blue), const SizedBox(width: 5), Expanded(child: Text(_rainText, style: const TextStyle(fontSize: 16)))])
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20), width: double.infinity, color: Colors.green[100],
              child: const Text("စိုက်ပျိုးရေး လက်စွဲ", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
            ExpansionTile(
              leading: const Icon(Icons.inventory),
              title: const Text("အိမ်ရှိပစ္စည်းစာရင်း", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _itemCtrl, decoration: const InputDecoration(hintText: "ပစ္စည်းအသစ်ထည့်ရန်"))),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
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
                      title: Text(item),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) _selectedInventory.add(item);
                          else _selectedInventory.remove(item);
                          _saveInventory();
                        });
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _inventoryList.remove(item);
                            _selectedInventory.remove(item);
                            _saveInventory();
                          });
                        },
                      ),
                    );
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigButton(String text, Color color, VoidCallback onTap) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: double.infinity, height: 100, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), onPressed: onTap, child: Text(text, style: const TextStyle(fontSize: 24)))));
  }

  int _secretCounter = 0;
  Widget _buildVersionLink() {
    return GestureDetector(
      onTap: () {
        _secretCounter++;
        if (_secretCounter >= 5) { _secretCounter = 0; _askPassword(); }
      },
      child: const Padding(padding: EdgeInsets.all(20), child: Text("App Version: 1.0.0", style: TextStyle(color: Colors.grey)))
    );
  }

  void _askPassword() {
    final passCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Password"), content: TextField(controller: passCtrl, obscureText: true), actions: [TextButton(onPressed: () { if (passCtrl.text == "1500") { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (c) => const SecretDoor())); } }, child: const Text("Confirm"))]));
  }
}
