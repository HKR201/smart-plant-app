import 'package:flutter/material.dart';
import 'database_helper.dart';

class CareLogsScreen extends StatefulWidget {
  const CareLogsScreen({super.key});

  @override
  State<CareLogsScreen> createState() => _CareLogsScreenState();
}

class _CareLogsScreenState extends State<CareLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final data = await DatabaseHelper.instance.getPlants();
    // Advice (အကြံဉာဏ်) ပါရှိသော မှတ်တမ်းများကိုသာ စစ်ထုတ်ယူခြင်း
    setState(() {
      _logs = data.where((item) => item['advice'] != null && item['advice'].toString().isNotEmpty).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📒 မှတ်သားထားသော အကြံဉာဏ်များ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('မှတ်တမ်း မရှိသေးပါ', style: TextStyle(fontSize: 24, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                            const Divider(),
                            Text(log['advice'], style: const TextStyle(fontSize: 22, height: 1.5)),
                            const SizedBox(height: 10),
                            Text('သိမ်းဆည်းသည့်ရက် - ${log['saveDate'].toString().substring(0, 10)}', 
                                style: const TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
