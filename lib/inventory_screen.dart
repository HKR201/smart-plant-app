import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // AppState ကို သုံးရန်

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final TextEditingController textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('အိမ်ရှိပစ္စည်းများ'),
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
              title: Text(key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              value: state.homeInventory[key],
              onChanged: (bool? value) {
                state.toggleInventory(key);
              },
              activeColor: Colors.green,
              controlAffinity: ListTileControlAffinity.leading,
              secondary: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => state.removeInventoryItem(key),
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, textController, state),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('အသစ်ထည့်မည်', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, TextEditingController controller, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ပစ္စည်းအသစ် ထည့်ရန်'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'ဥပမာ - နွားချေး')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('မလုပ်တော့ပါ')),
          ElevatedButton(
            onPressed: () {
              state.addInventoryItem(controller.text);
              controller.clear();
              Navigator.pop(context);
            },
            child: const Text('ထည့်မည်'),
          ),
        ],
      ),
    );
  }
}
