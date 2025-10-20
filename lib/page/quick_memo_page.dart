import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class QuickMemoPage extends StatefulWidget {
  const QuickMemoPage({super.key});

  @override
  State<QuickMemoPage> createState() => _QuickMemoPageState();
}

class _QuickMemoPageState extends State<QuickMemoPage> {
  final _box = GetStorage();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final data = _box.read('quick_memo');
    if (data != null) {
      _items = List<Map<String, dynamic>>.from(data);
    }
    setState(() {});
  }

  void _delete(int id) {
    _items.removeWhere((e) => e['id'] == id);
    _box.write('quick_memo', _items);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⭐ 빠른 메모')),
      body: _items.isEmpty
          ? const Center(child: Text('저장된 문장이 없습니다'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final memo = _items[i];
                return ListTile(
                  title: SelectableText(memo['content']),
                  subtitle: Text(
                    memo['time'].substring(0, 19),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _delete(memo['id']),
                  ),
                  onTap: () {
                    Navigator.pop(context, memo['content']);
                  },
                );
              },
            ),
    );
  }
}
