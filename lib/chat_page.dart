import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:worldtalk/big_screen.dart';
import 'package:worldtalk/qr_socket_chat.dart';
import 'models/message_model.dart';
import 'services/openai_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'dart:math';

class DualChatPage extends StatefulWidget {
  const DualChatPage({super.key});

  @override
  State<DualChatPage> createState() => _DualChatPageState();
}

class _DualChatPageState extends State<DualChatPage> {
  final _ai = OpenAIService();
  final _speech = SpeechService();
  final _controller = TextEditingController();
  final _box = GetStorage();
  double _fontSize = 12;

  List<Message> _messages = [];
  bool _isAturn = true;

  String _aLang = 'korean';
  String _bLang = 'english';
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isAtBottom = true;
  double _soundLevel = 0.0;
  String _partialText = '';
  final ScrollController _scrollController = ScrollController();
  // 각 언어별 locale
  Map<String, String> localeMap = {
    'korean': 'ko_KR',
    'english': 'en_US',
    'japanese': 'ja_JP',
    'vietnamese': 'vi_VN',
    'thai': 'th_TH',
  };
  final _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _speech.init();
    final saved = _box.read('dual_chat');
    // 저장된 폰트 크기 불러오기
    _fontSize = _box.read('font_size') ?? 18;
    if (saved != null) {
      _messages = List<Map<String, dynamic>>.from(
        saved,
      ).map((e) => Message.fromJson(e)).toList();
    }
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // 오차 허용 (약간 위로 올려도 하단으로 인식)
    final isBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    if (isBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isBottom;
      });
    }
  }

  void _save() =>
      _box.write('dual_chat', _messages.map((e) => e.toJson()).toList());

  Future<void> _sendMessage(String text) async {
    final fromLang = _isAturn ? _aLang : _bLang;
    final toLang = _isAturn ? _bLang : _aLang;
    final speaker = _isAturn ? '🅰️ A' : '🅱️ B';

    // 번역
    final translated = await _ai.translateText(text, fromLang, toLang);
    final combined = "$speaker\n$text\n\n🌐 [$toLang]\n$translated";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(microseconds: 10),
          curve: Curves.easeOut,
        );
      }
    });
    setState(() {
      _messages.add(Message(role: speaker, content: combined));
      _isAturn = !_isAturn;
    });
    _save();

    // ✅ 번역된 문장을 TTS로 출력
    await _tts.speak(translated, toLang);
    // ✅ 메시지 추가 후 스크롤 맨 아래로 이동
  }

  Future<void> _recordSpeech() async {
    final lang = _isAturn ? _aLang : _bLang;
    final locale = localeMap[lang] ?? 'en_US';

    setState(() {
      _isListening = true;
      _soundLevel = 0;
      _partialText = '';
    });

    final text = await _speech.listenOnce(
      localeId: locale,
      onResult: (recognized) {
        setState(() => _partialText = recognized);
      },
      onSoundLevel: (level) {
        setState(() => _soundLevel = level);
      },
    );

    setState(() => _isListening = false);

    if (text.isNotEmpty) {
      await _sendMessage(text);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성이 인식되지 않았습니다.')));
    }
  }

  void _showLangDialog(bool isA) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(isA ? '🅰️ A 언어 선택' : '🅱️ B 언어 선택'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langButton('kr', '한국어', 'korean', isA),
                _langButton('us', 'English', 'english', isA),
                _langButton('jp', '日本語', 'japanese', isA),
                _langButton('vn', 'Tiếng Việt', 'vietnamese', isA),
                // _langButton('th', 'ไทย', 'thai', isA),
                _langButton('id', 'Bahasa Indonesia', 'indonesian', isA),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _langButton(String assetName, String title, String value, bool isA) {
    return ListTile(
      leading: Container(
        width: 30,
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.transparent,
          child: Image(image: AssetImage('assets/flags/$assetName.png')),
        ),
      ),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      onTap: () {
        setState(() {
          if (isA)
            _aLang = value;
          else
            _bLang = value;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              '⚙️ 설정',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // 🅰️ 폰트 크기 조절 슬라이더
            Text(
              '글자 크기: ${_fontSize.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 18),
            ),
            Slider(
              min: 12,
              max: 28,
              divisions: 7,
              value: _fontSize,
              label: _fontSize.toStringAsFixed(1),
              onChanged: (v) {
                setState(() {
                  _fontSize = v;
                  _box.write('font_size', _fontSize);
                });
              },
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1),

            // 🗑 대화내용 삭제
            ListTile(
              leading: Stack(
                children: [
                  Icon(Icons.message, size: 40),
                  Positioned(
                    left: 16,
                    bottom: -5,

                    child: Icon(Icons.delete, color: Colors.red, size: 30),
                  ),
                ],
              ),
              title: const Text(
                '대화내용 전체 삭제',
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('모든 대화를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          _box.remove('dual_chat');
                          setState(() => _messages.clear());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🗑 대화가 삭제되었습니다')),
                          );
                        },
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),
            const Divider(thickness: 1),
            const Text(
              'ver 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildSettingsDrawer(), // ✅ 설정 Drawer 추가
      // appBar: AppBar(
      //   actions: [
      //     IconButton(
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute<void>(
      //             builder: (BuildContext context) => QrSocketPage(),
      //           ),
      //         );
      //       },
      //       icon: Icon(Icons.qr_code),
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _showLangDialog(true),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        // border: Border.all(),
                        color: Colors.blue.shade100,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/flags/${_aLang == 'korean'
                                  ? 'kr'
                                  : _aLang == 'english'
                                  ? 'us'
                                  : _aLang == 'japanese'
                                  ? 'jp'
                                  : _aLang == 'vietnamese'
                                  ? 'vn'
                                  : _aLang == 'thai'
                                  ? 'th'
                                  : 'id'}.png',
                            ),
                          ),
                          Text(
                            'A: $_aLang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.change_circle, size: 30),
                  GestureDetector(
                    onTap: () => _showLangDialog(false),
                    child: Container(
                      padding: EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        // border: Border.all(),
                        color: Colors.green.shade100,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/flags/${_bLang == 'korean'
                                  ? 'kr'
                                  : _bLang == 'english'
                                  ? 'us'
                                  : _bLang == 'japanese'
                                  ? 'jp'
                                  : _bLang == 'vietnamese'
                                  ? 'vn'
                                  : _bLang == 'thai'
                                  ? 'th'
                                  : 'id'}.png',
                            ),
                          ),
                          Text(
                            'B: $_bLang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  EndDrawerButton(),
                ],
              ),
            ),
            const Divider(),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  final isA = msg.role.contains('A');
                  final parts = msg.content.split(RegExp(r'\n\\s*\\n'));

                  return GestureDetector(
                    onTap: () {
                      print('tap');
                      _saveSingleMessage(msg.content);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isA
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          if (isA) ...[
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                'A',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 🅰️ 왼쪽 말풍선
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                    bottomLeft: Radius.circular(0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(1, 2),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...parts.map(
                                      (p) => SelectableText(
                                        p.trim(),
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    // Align(
                                    //   alignment: Alignment.bottomRight,
                                    //   child: IconButton(
                                    //     icon: const Icon(
                                    //       Icons.star_border,
                                    //       size: 20,
                                    //     ),
                                    //     color: Colors.grey.shade600,
                                    //     tooltip: "이 문장 저장",
                                    //     onPressed: () =>
                                    //         _saveSingleMessage(msg.content),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            // 🅱️ 오른쪽 말풍선
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(4),
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(-1, 2),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...parts.map(
                                      (p) => SelectableText(
                                        p.trim(),
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    // Align(
                                    //   alignment: Alignment.bottomRight,
                                    //   child: IconButton(
                                    //     icon: const Icon(
                                    //       Icons.star_border,
                                    //       size: 20,
                                    //     ),
                                    //     color: Colors.grey.shade600,
                                    //     tooltip: "이 문장 저장",
                                    //     onPressed: () =>
                                    //         _saveSingleMessage(msg.content),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green,
                              child: Text(
                                'B',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            //-------------전체 대화 저장 --------------------
            // Row(
            //   children: [
            //     ElevatedButton.icon(
            //       onPressed: () {
            //         // memo 저장
            //         final memoList = List<Map<String, dynamic>>.from(
            //           _box.read('memo') ?? [],
            //         );
            //         final newMemo = {
            //           'id': DateTime.now().millisecondsSinceEpoch,
            //           'content': _messages.map((e) => e.toJson()).toList(),
            //           'time': DateTime.now().toIso8601String(),
            //         };
            //         memoList.add(newMemo);
            //         _box.write('memo', memoList);

            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(content: Text('📘 메모에 저장되었습니다!')),
            //         );
            //       },
            //       icon: const Icon(Icons.save),
            //       label: const Text('Save to Memo'),
            //     ),
            //   ],
            // ),
            if (!_isAtBottom)
              GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.amber,
                  height: 30,
                  child: Icon(Icons.keyboard_arrow_down_outlined),
                ),
              ),
            ListTile(
              title: Row(
                children: [
                  if (_isListening)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 4,
                        bottom: 10,
                      ),
                      child: Text(
                        _partialText.isNotEmpty
                            ? '🗣 $_partialText'
                            : '🎧 듣는 중...',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: max(40, 50 + _soundLevel * 2),
                      height: max(40, 50 + _soundLevel * 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.hearing : Icons.mic,
                      color: _isListening ? Colors.redAccent : Colors.grey,
                    ),
                    onPressed: _isListening ? _speech.stop : _recordSpeech,
                  ),
                ],
              ),
            ),

            Row(
              children: [
                SizedBox(width: 10),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAturn = !_isAturn;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(),
                      color: _isAturn ? Colors.blue : Colors.green,
                    ),

                    child: Text(
                      _isAturn ? 'A' : 'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: _isAturn ? 'A 말하기 / 입력...' : 'B 말하기 / 입력...',
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        _sendMessage(v.trim());
                        _controller.clear();
                      }
                    },
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      _sendMessage(_controller.text.trim());
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSingleMessage(String content) {
    final memoList = List<Map<String, dynamic>>.from(
      _box.read('quick_memo') ?? [],
    );

    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'content': content,
      'time': DateTime.now().toIso8601String(),
    };

    // 중복 방지 (같은 문장 있으면 저장 안 함)
    final exists = memoList.any((m) => m['content'] == content);
    if (!exists) {
      memoList.add(newItem);
      _box.write('quick_memo', memoList);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⭐ 이 대화를 빠른메모에 저장했습니다')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 저장된 문장입니다')));
    }
  }
}
