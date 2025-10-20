import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:worldtalk/models/message_model.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final _box = GetStorage();
  List<Map<String, dynamic>> _memos = [];

  @override
  void initState() {
    super.initState();
    final saved = _box.read('memo');
    if (saved != null) {
      _memos = List<Map<String, dynamic>>.from(saved);
    }
  }

  void _deleteMemo(int id) {
    setState(() {
      _memos.removeWhere((m) => m['id'] == id);
      _box.write('memo', _memos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📘 Saved Memos')),
      body: _memos.isEmpty
          ? const Center(child: Text('저장된 메모가 없습니다.'))
          : ListView.builder(
              itemCount: _memos.length,
              itemBuilder: (context, i) {
                final memo = _memos[i];
                final messages = (memo['content'] as List)
                    .map((e) => Message.fromJson(e))
                    .toList();
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      '🕒 ${memo['time'].substring(0, 19)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: messages
                          .take(3)
                          .map(
                            (m) => Text(
                              m.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                          .toList(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteMemo(memo['id']),
                    ),
                    onTap: () {
                      // 상세보기 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemoDetailPage(messages: messages),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class MemoDetailPage extends StatelessWidget {
  final List<Message> messages;
  const MemoDetailPage({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🗒 Memo Detail')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final msg = messages[i];
          final isA = msg.role.contains('A');
          return Align(
            alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isA ? Colors.blue.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(msg.content),
            ),
          );
        },
      ),
    );
  }
}
