import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:worldtalk/page/memo_page.dart';
import 'package:worldtalk/page/quick_memo_page.dart';
import 'package:worldtalk/page/save_page.dart';
import 'package:worldtalk/page/search_page.dart';
import 'chat_page.dart'; // 기존 DualChatPage import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // 네비게이션 탭별 페이지 목록
  final List<Widget> _pages = const [
    DualChatPage(), // Talk
    QuickMemoPage(), // Memo
    // SearchPage(), // Search
    // SavePage(), // Save
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Talk'),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Memo'),
          // BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          // BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Save'),
        ],
      ),
    );
  }
}
